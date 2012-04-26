class DatasiftPushPost
  include VideosHelper

  @queue = :datasift

  def self.combinalities(string)
    # generate the word combinations in the tweet (to find topics based on)
    words = string.downcase.gsub("'s", '').gsub(/[^a-z1-9 ]/, '')
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

  def self.perform(interaction, tweet_content)

    combinations = DatasiftPushPost.combinalities(tweet_content)
    # we skip this post if there has been another post pushed to all the mentioned topics in the past x seconds
    skip = true
    topics = Topic.where(:datasift_tags => {"$in" => combinations}).to_a
    topics.each_with_index do |t,i|
      if !t.datasift_last_pushed || (Time.now.to_i - t.datasift_last_pushed.to_i > 75)
        # dont skip this post, there is a topic that has not had a datasift post in the past x seconds
        skip = false
        t.datasift_last_pushed = Time.now
        t.save
      end
    end

    if skip == false
      begin
        # grab info with embedly
        embedly_key = 'ca77b5aae56d11e0a9544040d3dc5c07'
        buffer = open("http://api.embed.ly/1/preview?key=#{embedly_key}&url=#{interaction['twitter']['retweet']['links'][0]}&format=json", "UserAgent" => "Ruby-Wget").read
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

      # blacklist certain sites as sources
      if ['facebook', 'twitter', 'twitpic', 'google+', 'amazon', 'ebay', 'instagram'].include?(link_data['provider_name'].downcase)
        return
      end

      post = link_data['url'] ? Post.where('sources.url' => link_data['url']).first : nil

      # create the post if it is new
      unless post

        # new combinations using the link description as well
        combinations = DatasiftPushPost.combinalities("#{tweet_content} #{link_data['description']}")
        topics = Topic.where(:datasift_tags => {"$in" => combinations}).to_a

        response = {
          :type => 'Link',
          :source_name => link_data['provider_name'],
          :source_url => link_data['url'],
          :title => link_data['title']
        }

        # remove the site title that often comes after the |, ie google buys microsoft | tech crunch
        if response[:title]
          response[:title] = response[:title].split('|')
          # figure out if the title is before or after the |
          if response[:title].length > 1
            if response[:title][0].downcase.gsub(' ', '').strip == link_data['provider_name'].downcase.gsub(' ', '').strip
              response[:title] = response[:title].shift.join(' ')
            else
              response[:title] = response[:title].pop.join(' ')
            end
          end

          response[:title].strip!
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

        post = Post.post(response, User.limelight_user_id)
        post.tweet_id = interaction['twitter']['retweeted']['id']
        post.standalone_tweet = true

        topics.each_with_index do |t,i|
          # add the mentions
          if i == 0
            post.mention1_id = t.id
            post.mention1 = t.name
          elsif i == 1
            post.mention2_id = t.id
            post.mention2 = t.name
          end
        end

        post.save
      end
    else
      #puts 'skipped post'
    end
  end
end