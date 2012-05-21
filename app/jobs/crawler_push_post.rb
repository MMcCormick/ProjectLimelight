class CrawlerPushPost

  @queue = :medium

  class << self
    include VideosHelper

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
                      :sourceText => 'cleaned',
                      :maxRetrieve => 5
              }
      )
      tmp_entities = JSON.parse(postData.body)['entities']
      entities = []
      topics = []

      if tmp_entities
        tmp_entities.each_with_index do |e,i|
          if e['relevance'].to_f >= 0.7
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
            if !topic && e['type']
              type = Topic.where("aliases.slug" => e['type'].to_url).order_by(:score, :desc).first
              unless type
                type = Topic.new
                type.name = e['type']
                type.user_id = User.marc_id
                type.save
              end

              topic = Topic.new
              topic.name = e['disambiguated'] ? e['disambiguated']['name'] : e['text']
              topic.user_id = User.marc_id
              if e['disambiguated'] && e['disambiguated']['freebase']
                topic.freebase_id = e['disambiguated']['freebase']
              end
              saved = topic.save
              if saved
                topic.primary_type_id = type.id
                topic.primary_type = type.name
                topic.save
                TopicConnection.add(type_connection, topic, type, User.marc_id, {:pull => false, :reverse_pull => true})
              end
            end

            topics << topic if topic && topic.valid?
          end
        end
      end

      return if topics.length == 0

      # grab info with embedly
      begin
        buffer = open("http://api.embed.ly/1/preview?key=ca77b5aae56d11e0a9544040d3dc5c07&url=#{url}&format=json", "UserAgent" => "Ruby-Wget").read
        link_data = JSON.parse(buffer)
      rescue => e
        return
      end

      # Build the initial post data structure
      response = {
        :type => 'Link',
        :title => link_data['title'],
        :source_name => link_data['provider_name'],
        :source_url => link_data['url'],
        :source_content => link_data['description']
      }

      # remove the site title that often comes after/before the |, ie "google buys microsoft | tech crunch"
      if response[:title]
        response[:title] = response[:title].split('|')
        # Take out part of the title if one side of the | is shorter than the other AND includes the name of the provider
        if response[:title].length > 1
          if response[:title][0].length < response[:title][response[:title].length - 1].length && response[:title][0].to_url.include?(link_data['provider_name'].to_url)
            response[:title].shift
          elsif response[:title][response[:title].length - 1].length < response[:title][0].length && response[:title][response[:title].length - 1].to_url.include?(link_data['provider_name'].to_url)
            response[:title].pop
          end
        end
        response[:title] = response[:title].join(' ').strip
        response[:source_title] = response[:title]
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
      topics.each_with_index do |t,i|
        break if i > 4
        post.save_topic_mention(t)
      end

      if post.save
        crawler_source.posts_added += 1
        crawler_source.save
      else
        puts post.errors.to_a
      end
    end
  end
end