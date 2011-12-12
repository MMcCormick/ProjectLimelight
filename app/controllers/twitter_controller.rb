class TwitterController < ApplicationController
  before_filter :authenticate_user!
  include VideosHelper

  def show
    @site_style = 'narrow'
    @processed_tweets = []
    twitter = current_user.get_social_connect 'twitter'
    tweets = current_user.twitter.user_timeline(twitter.uid.to_i)
    tweet_ids = tweets.map{|t| t.id.to_s}
    tweet_posts = CoreObject.where(:tweet_id => {'$in' => tweet_ids})
    embedly_api = Embedly::API.new :key => 'ca77b5aae56d11e0a9544040d3dc5c07'
    tweets.each do |tweet|
      previous = tweet_posts.detect{|tp| tp.tweet_id.to_s == tweet.id.to_s}
      if previous
        @processed_tweets << {
                :where => :limelight,
                :post => previous
        }
        next
      end

      links = URI.extract(tweet.text)
      if links.length > 0
        obj = embedly_api.objectify :url => links[0]
        link_objectify = obj[0].marshal_dump
        link_obembed = link_objectify[:oembed]
      end

      cleaned_text = tweet.text
      links.each do |link|
        cleaned_text.gsub!(link, '')
      end

      new_tweet = {
        :where => :twitter,
        :id => tweet.id,
        :links => links,
        :text => cleaned_text,
        :type => 'Talk'
      }

      if link_objectify
        new_tweet[:link] = link_obembed
        new_tweet[:original_url] = link_obembed[:url]
        new_tweet[:provider] = link_obembed[:provider_name]
        if link_obembed[:type] == 'photo'
          new_tweet[:type] = 'Picture'
          new_tweet[:title] = cleaned_text
          new_tweet[:text] = ''
        end
        if link_obembed[:type] == 'video'
          new_tweet[:type] = 'Video'
          new_tweet[:title] = link_obembed[:title]
          new_tweet[:video_id] = video_id(link_obembed[:provider_name], link_objectify)
          new_tweet[:video_embed] = video_embed(nil, 110, 110, link_obembed[:provider_name], new_tweet[:video_id])
        end
        if link_obembed[:type] == 'link'
          new_tweet[:type] = 'Link'
          new_tweet[:title] = link_obembed[:title]
        end
      end

      @processed_tweets << new_tweet
    end
  end

  def create
    tweets = params[:tweets]
    tweets.each do |tweet_id, tweet|
      case tweet[:type]
        when 'Video'
          post = current_user.videos.build(tweet)
        when 'Picture'
          post = current_user.pictures.build(tweet)
          post.save_original_image
          post.save_images
        when 'Link'
          post = current_user.links.build(tweet)
          post.save_original_image
          post.save_images
        when 'Talk'
          post = current_user.talks.build(tweet)
      end

      post.save
    end

    render json: build_ajax_response(:ok, user_path(current_user), nil, nil, nil), status: :created
  end

end