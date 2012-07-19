class PullTweets

  @queue = :slow

  def self.perform
    users = User.where(:twitter_handle => {"$exists" => true})
    users.each do |user|
      # Get user's tweets
      tweets = Twitter.user_timeline(user.twitter_handle, :count => 50, :exclude_replies => true, :include_entities => true, :since_id => user.latest_tweet_id)
      tweets.each do |tweet|
        # Grab first url from tweet if it exists
        if tweet.urls.first
          response = fetch_url(tweet.urls.first.expanded_url)
          next if response.nil?
          # If there's already a post
          if response[:existing]
            post = response[:existing]
            # Otherwise create a new post
          else
            response[:type] = response[:type] && ['Link','Picture','Video'].include?(response[:type]) ? response[:type] : 'Link'
            params = {:source_url => response[:url],
                      :source_name => response[:provider_name],
                      :embed_html => response[:video],
                      :title => response[:title],
                      :type => response[:type],
                      :description => response[:description],
                      :pending_images => response[:images]
            }
            post = Kernel.const_get(response[:type]).new(params)
            post.user_id = user.id
            post.status = "pending"
          end

          if post && !post.get_share(user.id)
            text_without_url = tweet.text
            tweet.urls.each do |u|
              text_without_url.slice!(u.url)
            end
            share = post.add_share(user.id, text_without_url)
            share.status = "pending"
            share.add_medium({:source => "Twitter", :id => tweet.id, :url => "https://twitter.com/#{user.twitter_handle}/statuses/#{tweet.id}"})

            if post.valid?
              post.save
            end
          end
        end
        user.latest_tweet_id = tweet.id
      end
      user.save
    end
  end
end