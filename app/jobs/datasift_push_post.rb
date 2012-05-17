class DatasiftPushPost

  @queue = :datasift

  class << self
    include VideosHelper

    def combinalities(string)
      return [] unless string && !string.blank?

      # generate the word combinations in the tweet (to find topics based on) and remove short words
      words = string.downcase.gsub("'s", '').gsub(/[^a-z1-9 ]/, '').split.select { |w| w.length > 2 }.join(' ')
      words = words.split(" ")
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

    def perform(interaction, tweet_content, url)
      begin
        # grab info with embedly
        buffer = open("http://api.embed.ly/1/preview?key=ca77b5aae56d11e0a9544040d3dc5c07&url=#{url}&format=json", "UserAgent" => "Ruby-Wget").read
      rescue => e
        #puts 'embedly error'
        #puts e
        return
      end

      # convert JSON data into a hash
      link_data = JSON.parse(buffer)

      # replace the link with empty text in the tweet
      tweet_content.gsub!(/(?:f|ht)tps?:\/[^\s]+/, '')
      tweet_content.strip!
      tweet_content.chomp!('-|_ ')
      tweet_content.strip!

      # FILTERS

      # blacklist certain sites as sources
      return if ['facebook', 'twitter', 'twitpic', 'google+', 'amazon', 'ebay', 'instagram'].include?(link_data['provider_name'].downcase)

      # skip if it is a root source (www.google.com is the root and www.google.com is the url submitted)
      return if link_data['provider_url'].to_url == url.to_url

      # associated press does not return actual titles with their stories and looks fucking dumb on feeds. skiiiippp.
      return if link_data['title'] && link_data['title'].to_url == 'news-from-the-associated-press'

      # extract topics from the text
      combinations = DatasiftPushPost.combinalities(tweet_content)
      # extract topics from the link with alchemy api
      postData = Net::HTTP.post_form(
              URI.parse("http://access.alchemyapi.com/calls/url/URLGetRankedNamedEntities"),
              {
                      'url' => url,
                      'apikey' => '1deee8afa82d7ba26ce5c5c7ceda960691f7e1b8',
                      'outputMode' => 'json'
              }
      )
      tmp_entities = JSON.parse(postData.body)['entities']
      entities = []

      if tmp_entities
        tmp_entities.each_with_index do |e,i|
          if e['relevance'].to_f >= 0.6
            entities << e['text'].downcase
            if e['disambiguated']
              entities << e['disambiguated']['name'].downcase
            end
          end
        end
        entities.uniq!
      end

      combinations << entities
      combinations.uniq!

      # we skip this post if there has been another post pushed to all the mentioned topics in the past x seconds
      skip = true
      topics = Topic.where(:datasift_tags => {"$in" => combinations}).to_a
      topics.each_with_index do |t,i|
        if !t.datasift_last_pushed || (Time.now.to_i - t.datasift_last_pushed.to_i > 75)
          # dont skip this post, there is a topic that has not had a datasift post in the past x seconds
          skip = false
        end
      end

      if skip == false
        text_content = link_data['title']
        combinations = DatasiftPushPost.combinalities(text_content)
        combinations << entities
        combinations.uniq!
        topics = Topic.where(:datasift_tags => {"$in" => combinations}).order_by(:score, :desc).to_a

        # check to see if a news story covering this story has already been submitted
        existing_post = Post.find_similar(topics)
        if existing_post
          source = SourceSnippet.new
          source.name = link_data['provider_name']
          source.url = link_data['url']
          source.title = link_data['title']
          source.content = link_data['description']
          existing_post.add_source(source)
          existing_post.save
        else
          response = {
            :type => 'Link',
            :title => link_data['title'],
            :source_name => link_data['provider_name'],
            :source_url => link_data['url'],
            :source_content => link_data['description']
          }

          # remove the site title that often comes after the |, ie google buys microsoft | tech crunch
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

          if link_data['object']
            if link_data['object']['type'] == 'video'
              response[:type] = 'Video'
              response[:embed_html] = video_embed(nil, 120, 120, link_data['provider_name'], nil, link_data['object']['html'])
            elsif link_data['object']['type'] == 'photo'
              response[:type] = 'Picture'
              response[:remote_image_url] = link_data['object']['url']
            end
          end

          puts "creating post"
          post = Post.post(response, User.limelight_user_id)
          post.tweet_id = interaction['twitter']['retweeted'] ? interaction['twitter']['retweeted']['id'] : interaction['twitter']['id']
          post.standalone_tweet = true
          post.alchemy_entities = entities
          topics.each_with_index do |t,i|
            break if i > 3
            t.datasift_last_pushed = Time.now
            t.save
            post.save_topic_mention(t)
          end

          if post.save
            puts 'saved'
          else
            puts post.errors.to_a
          end
        end
      else
        puts 'skipped post'
      end
    end
  end
end