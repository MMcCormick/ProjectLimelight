class TwitterController < ApplicationController
  before_filter :authenticate_user!
  include VideosHelper

  def show
    @site_style = 'narrow'
    @processed_tweets = []
    twitter = current_user.get_social_connect 'twitter'
    twitter_id = params[:twitter_id] ? params[:twitter_id] : twitter.uid.to_i
    tweets = current_user.twitter.user_timeline(twitter_id, :count => 50, :include_rts => false, :include_entities => true, :trim_user => true, :exclude_replies => true)
    tweet_ids = tweets.map{|t| t.id.to_s}
    tweet_posts = CoreObject.where(:tweet_id => {'$in' => tweet_ids})
    embedly_api = Embedly::API.new :key => 'ca77b5aae56d11e0a9544040d3dc5c07'
    tweets.each_with_index do |tweet, i|
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
        :content => cleaned_text,
        :type => 'Talk',
        :mentions => []
      }

      # parse twitter hashes
      hashes = []
      cleaned_text.scan(/#([a-zA-Z0-9,!\-_:'&\?\$]*)/).map do |hash|
        hashes << hash[0].downcase unless hashes.include?(hash[0].downcase)
      end
      if hashes.length > 0
        matches = Topic.any_of({:short_name => {'$in' => hashes}}, {'aliases.hash' => {'$in' => hashes}, 'aliases.ooac' => true}).to_a
        new_tweet[:mentions] = matches
      end

      if link_objectify
        new_tweet[:link] = link_obembed
        new_tweet[:original_url] = link_obembed[:url]
        new_tweet[:provider] = link_obembed[:provider_name]
        if link_obembed[:type] == 'photo'
          new_tweet[:type] = 'Picture'
          new_tweet[:title] = cleaned_text
          new_tweet[:content] = ''
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

      # parse text and create word combinations for titles
      unless new_tweet[:title].blank?
        matches = Topic.parse_text(new_tweet[:title])
        if matches.length > 0
          if new_tweet[:mentions].length > 0
            new_tweet[:mentions].concat matches
          else
            new_tweet[:mentions] = matches
          end
        end
      end

      # parse text and create word combinations for main content. take out @ and # tags before.
      words = cleaned_text.gsub(/[\#|@]([a-zA-Z0-9,!\-_:'&\?\$]*)/, '')
      matches = Topic.parse_text(words)
      if matches.length > 0
        if new_tweet[:mentions].length > 0
          new_tweet[:mentions].concat matches
        else
          new_tweet[:mentions] = matches
        end
      end

      new_tweet[:title_raw] = new_tweet[:title].blank? ? '' : new_tweet[:title].dup
      new_tweet[:content_raw] = new_tweet[:content].blank? ? '' : new_tweet[:content].dup

      # take out duplicate mentions
      if new_tweet[:mentions].length > 0
        used_ids = []
        mentions = []
        new_tweet[:mentions].each do |m|
          unless used_ids.include?(m.id)
            mentions << m
            used_ids << m.id
          end
        end
        new_tweet[:mentions] = mentions

        # sort mentions by alias length
        new_tweet[:mentions] = new_tweet[:mentions].sort_by {|m| (-1)*m.name.length}

        # replace mentions in the raw content
        used_mentions = []
        new_tweet[:mentions].each do |mention|
          already_used = used_mentions.detect{|m| m.name.include?(mention.name)}
          unless already_used
            mention.aliases.each do |topic_alias|
              title_index, content_index = nil
              unless new_tweet[:title_raw].blank?
                title_index = new_tweet[:title_raw].index(/\b#{topic_alias.name}\b/i)
                if title_index
                  new_tweet[:title_raw].gsub!(/[#]*\b(#{topic_alias.name})\b/i, "#[#{mention.id}#\\1]")
                end
              end

              unless new_tweet[:content_raw].blank?
                content_index = new_tweet[:content_raw].index(/\b#{topic_alias.name}\b/i)
                if content_index
                  new_tweet[:content_raw].gsub!(/[#]*\b(#{topic_alias.name})\b/i, "#[#{mention.id}#\\1]")
                end
              end

              if title_index || content_index
                used_mentions << mention
              end
            end
          end
        end
        new_tweet[:mentions] = used_mentions
      end

      # store a string of mention names
      new_tweet[:mentions_string] = new_tweet[:mentions].map{|m| m.name}

      @processed_tweets << new_tweet
    end

    # Find things for the user to follow
    tweet_text = ''
    10.times do |i|
      tweets = current_user.twitter.user_timeline(twitter_id, :count => 200*(i+1), :include_rts => false, :include_entities => true, :trim_user => true, :exclude_replies => true)
      tweets.each do |tweet|
        tweet_text += "#{tweet[:text]} "
      end
    end


    total_mentions = Topic.parse_text(tweet_text, false, true)
    @suggestions = Topic.get_graph(total_mentions)
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