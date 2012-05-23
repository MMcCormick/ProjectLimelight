class CrawlerPushPost

  @queue = :medium

  class << self
    include VideosHelper
    include ActiveSupport::Inflector

    def combinalities(string)
      return [] unless string && !string.blank?

      # generate the word combinations in the tweet (to find topics based on) and remove short words
      words = (string.split - Topic.stop_words).join(' ').gsub('-', ' ').downcase.gsub("'s", '').gsub(/[^a-z1-9 ]/, '').split.select { |w| w.length > 2 }.join(' ')
      words = words.split(" ")
      singular_words = words.map{|w| w.singularize}
      words = singular_words
      combinaties = []
      i=0
      while i <= words.length-1
        combinaties << words[i].downcase
        unless i == words.length-1
          words[(i+1)..(words.length-1)].each{|volgend_element|
            combinaties<<(combinaties.last.dup<<" #{volgend_element}")
          }
        end
        i+=1
      end
      combinaties
    end

    def perform(url, crawler_source_id)
      type_connection = TopicConnection.find(Topic.type_of_id)
      crawler_source = CrawlerSource.find(crawler_source_id)

      # extract topics from the link with alchemy api
      postData = Net::HTTP.post_form(
              URI.parse("http://access.alchemyapi.com/calls/url/URLGetRankedNamedEntities"),
              {
                      :url => url,
                      :apikey => '1deee8afa82d7ba26ce5c5c7ceda960691f7e1b8',
                      :outputMode => 'json',
                      #:sourceText => 'cleaned',
                      :maxRetrieve => 5
              }
      )
      tmp_entities = JSON.parse(postData.body)['entities']
      entities = []
      topics = []

      if tmp_entities
        tmp_entities.each_with_index do |e,i|
          if e['relevance'].to_f >= 0.75
            entities << e
            if e['disambiguated'] && e['disambiguated']['freebase']
              topic = Topic.where(:freebase_id => e['disambiguated']['freebase']).first
              unless topic
                topic = Topic.where("aliases.slug" => e['disambiguated']['name'].to_url).order_by(:score, :desc).first
              end
            else
              name = e['disambiguated'] ? e['disambiguated']['name'].to_url : e['text'].to_url
              topic = Topic.where("aliases.slug" => name).order_by(:score, :desc).first
            end

            # create the topic if it's not already in the DB
            if !topic
              type = nil
              if e['type'] && ['company','product','technology','organization'].include?(e['type'].downcase)
                type = Topic.where("aliases.slug" => e['type'].to_url).order_by(:score, :desc).first
                unless type
                  type = Topic.new
                  type.name = e['type']
                  type.user_id = User.marc_id
                  type.save
                end
              end

              topic = Topic.new
              topic.name = e['disambiguated'] ? e['disambiguated']['name'] : e['text']
              topic.user_id = User.marc_id
              if e['disambiguated'] && e['disambiguated']['freebase']
                topic.freebase_id = e['disambiguated']['freebase']
              end
              saved = topic.save
              if saved
                if type
                  topic.primary_type_id = type.id
                  topic.primary_type = type.name
                  topic.save
                  TopicConnection.add(type_connection, topic, type, User.marc_id, {:pull => false, :reverse_pull => true})
                end
              end
            end

            topics << topic if topic && topic.valid?
          end
        end
      end

      if topics.length == 0
        puts "no topics found"
        return
      end

      # grab info with embedly
      begin
        buffer = open("http://api.embed.ly/1/preview?key=ca77b5aae56d11e0a9544040d3dc5c07&url=#{url}&format=json", "UserAgent" => "Ruby-Wget").read
        link_data = JSON.parse(buffer)
      rescue => e
        puts "embedly fail"
        return
      end

      # get topics in the news title
      combinations = CrawlerPushPost.combinalities(link_data['title'])

      #TODO: Make this require typed topics when we have more typed topics filled out
      extra_topics = Topic.where("aliases.slug" => {"$in" => combinations.map{|c| c.to_url}})
      extra_topics.each do |t|
        topics << t
      end

      # Build the initial post data structure
      response = {
        :type => 'Link',
        :title => link_data['title'].html_safe,
        :source_name => link_data['provider_name'].html_safe,
        :source_url => link_data['url'],
        :source_content => link_data['description'].html_safe
      }

      # remove the site title that often comes after/before the |, ie "google buys microsoft | tech crunch"
      if response[:title]
        response[:title] = response[:title].split(' ')

        # find and take out any provider names at the end of string
        if response[:title].last.gsub(' ', '').to_url.include? (link_data['provider_name'].gsub(' ', '').to_url)
          response[:title].pop
          if ['-', '|', '--', '/', '\\'].include?(response[:title].last)
            response[:title].pop
          end
        end

        # find and take out any provider names at the start of string
        if response[:title].first.gsub(' ', '').to_url.include? (link_data['provider_name'].gsub(' ', '').to_url)
          response[:title].shift
          if ['-', '|', '--', '/', '\\'].include?(response[:title].first)
            response[:title].shift
          end
        end

        response[:title] = response[:title].join(' ').strip
        response[:source_title] = response[:title].html_safe
      end

      if link_data['images'] && link_data['images'].length > 0
        image = link_data['images'].max_by{|v| v.size}
        if image['width'] >= 210
          response[:remote_image_url] = image['url']
        end
      end

      # Grab the video or photo if this is a video/photo link
      if link_data['object']
        if link_data['object']['type'] == 'video'
          response[:type] = 'Video'
          response[:embed_html] = video_embed(nil, 120, 120, link_data['provider_name'], nil, link_data['object']['html'])
        elsif link_data['object']['type'] == 'photo'
          response[:type] = 'Picture'
          response[:remote_image_url] = link_data['object']['url']
        end
      end

      post = Post.post(response, User.limelight_user_id)
      post.category = crawler_source.category
      used_ids = []
      puts "starting topic loop"
      topics.each do |t|
        puts "topic #{t.name}"
        break if used_ids.length > 4
        next if used_ids.include?(t.id.to_s)
        puts "used"
        used_ids << t.id.to_s
        post.save_topic_mention(t)
      end

      if post.save
        puts "post saved"
        crawler_source.posts_added += 1
        crawler_source.save
      else
        puts "errors"
        puts post.errors.to_a
      end
    end
  end
end