require "net/http"
include EmbedlyHelper

class TestingController < ApplicationController

  def test
    users = User.where(:twitter_handle => {"$exists" => true})
    users.each do |user|
      # Get user's tweets
      tweets = Twitter.user_timeline(user.twitter_handle, :count => 10, :exclude_replies => true, :include_entities => true)
      tweets.each do |tweet|
        # Grab first url from tweet if it exists
        if tweet.urls.first
          response = fetch_url(tweet.urls.first.expanded_url)
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
            comment = post.add_comment(user.id, tweet.text)

            if !comment || comment.valid?
              share = post.add_share(user.id, tweet.text)
              share.add_medium({:source => "Twitter", :id => tweet.id, :url => "https://twitter.com/#{user.twitter_handle}/statuses/#{tweet.id}"})

              if post.valid?
                post.save
              end
            end
          end
        end
      end
    end

    #authorize! :manage, :all
    #
    #@count1 = 0
    #@count2 = 0

    #Resque.enqueue(TestJob)

  end

end