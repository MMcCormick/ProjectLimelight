require 'datasift'
require "uri"

namespace :datasift do

  desc "Consume datasift stream."
  task :consume_stream => :environment do
    include VideosHelper

    datasift_user = DataSift::User.new("marbemac", "6acfce1c072652c8316f7d555c2d74d3")

    #definition = datasift_user.createDefinition('
    #  tag "4f0a629c5b1dc30008000335-Microsoft" { interaction.content any "#microsoft, microsoft" }
    #  tag "4eecf9fb2568b30004002238-Bill Clinton" { interaction.content any "#billclinton, bill clinton" }
    #  tag "4eea2ec9318d920005000039-Barack Obama" { interaction.content any "#barackobama, barack obama" }
    #  tag "4eea6171d8783e000500016e-Miit Romney" { interaction.content any "#mittromney, mitt romney" }
    #  tag "4f9604decddc7f148000001b-Macbook Pro" { interaction.content any "#macbookpro, macbook pro" }
    #  tag "4eecf9d32568b30004001784-Diablo III" { interaction.content any "#diablo3, diablo III, diablo 3" }
    #  tag "4f97005acddc7f1480000037-Guild Wars 2" { interaction.content any "#guildwars2, guild wars 2" }
    #  tag "4ef3a6addaa374000500001f-Beautiful" { interaction.content any "#beautiful, beautiful" }
    #  return {
    #    interaction.content ANY "#beautiful, beautiful, #diablo3, diablo III, diablo 3, #guildwars2, guild wars 2, #macbookpro, macbook pro, #microsoft, microsoft, #billclinton, bill clinton, #barackobama, barack obama, #mittromney, mitt romney"
    #    AND
    #    language.tag == "en"
    #    AND
    #    twitter.retweet.count >= 5
    #    AND
    #    twitter.retweet.links exists
    #  }
    #')
    #consumer = definition.getConsumer(DataSift::StreamConsumer::TYPE_HTTP)

    limelight_datasift = SiteData.where(:name => 'datasift').first
    if limelight_datasift
      puts "Consuming hash #{limelight_datasift.data['hash']} with DPU #{limelight_datasift.data['dpu']} compiled on #{limelight_datasift.data['created_at']}. Covers #{limelight_datasift.data['topic_count']} topics."
      consumer = datasift_user.getConsumer(DataSift::StreamConsumer::TYPE_HTTP, limelight_datasift.data['hash'])
    else
      raise "Missing limelight datasift definition. Have you compiled a datasift stream yet (enabled datasift on a topic)?"
    end

    user = User.find(User.limelight_user_id)
    consumer.consume(true) do |interaction|
      if interaction

        # filter tweets
        # no tweets that include @usernames
        tweet_content = interaction['twitter']['retweet']['text']
        tweet_content.gsub!(/\B#\w+/i, '')
        tweet_content.chomp!('-|_ ')
        tweet_content.strip!

        existing_post = Post.where(:tweet_id => interaction['twitter']['retweeted']['id']).first
        unless existing_post

          puts tweet_content

          #user = User.where("social_connects._id" => interaction['twitter']['retweeted']['user']['id'], "social_connects.provider" => "twitter").first
          #unless user
          #  user = User.new(
          #          :bio => interaction['twitter']['retweeted']['user']['description']
          #  )
          #  user.status = 'twitter'
          #  user.username_reset = true
          #  user.email_reset = true
          #  connect = SocialConnect.new(:uid => interaction['twitter']['retweeted']['user']['id'], :provider => 'twitter', :username => interaction['twitter']['retweeted']['user']['screen_name'])
          #  user.social_connects << connect
          #  user.use_fb_image = true if user.image_versions == 0
          #  user.update_social_denorms
          #  user.confirm!
          #end

          #if user.save
          begin
            # grab info with embedly
            embedly_key = 'ca77b5aae56d11e0a9544040d3dc5c07'
            buffer = open("http://api.embed.ly/1/preview?key=#{embedly_key}&url=#{interaction['twitter']['retweet']['links'][0]}&format=json", "UserAgent" => "Ruby-Wget").read
          rescue => e
            next
          end

          # convert JSON data into a hash
          link_data = JSON.parse(buffer)

          # replace the link with empty text in the tweet
          tweet_content.gsub!(/(?:f|ht)tps?:\/[^\s]+/, '')
          tweet_content.strip!
          tweet_content.chomp!('-|_ ')
          tweet_content.strip!

          post = link_data['url'] ? Post.where('sources.url' => link_data['url']).first : nil
          # create the post if it is new
          unless post
            puts 'New Post'

            response = {
              :type => 'Link',
              :source_name => link_data['provider_name'],
              :source_url => link_data['url'],
              :title => link_data['title']
            }

            #if link_data['provider_name'].to_url == user.username.to_url
            #  puts 'Self promotion post'
            #  next
            #end

            # remove the site title that often comes after the |, ie google buys microsoft | tech crunch
            response[:title] = response[:title].split('|')
            response[:title] = response[:title][0]
            response[:title].strip!

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

            post = Post.post(response, user.id)
            post.tweet_id = interaction['twitter']['retweeted']['id']
            post.standalone_tweet = true

            if interaction['interaction']['tags']
              interaction['interaction']['tags'].uniq!
              interaction['interaction']['tags'].each_with_index do |t,i|
                t = t.split('-')
                if i == 0
                  post.mention1_id = t[0]
                  post.mention1 = t[1]
                elsif i == 1
                  post.mention2_id = t[0]
                  post.mention2 = t[1]
                end
              end
            end

            post.save
          end

          # if the tweet is the same as the link title, skip it (self promotion tweet)
          #unless post && post.title.to_url.include?(tweet_content.to_url)
          #  talk = user.talks.new(
          #          :content => tweet_content,
          #          :tweet_id => interaction['twitter']['retweeted']['id'],
          #          :standalone_tweet => true
          #  )
          #  talk.created_at = interaction['twitter']['created_at']
          #  if post
          #    talk.parent_id = post.id
          #    #if new_post
          #    #  talk.first_talk = true
          #    #end
          #  end
          #
          #  if interaction['interaction']['tags']
          #    interaction['interaction']['tags'].each_with_index do |t,i|
          #      t = t.split('-')
          #      if i == 0
          #        talk.mention1_id = t[0]
          #        talk.mention1 = t[1]
          #      elsif i == 1
          #        talk.mention2_id = t[0]
          #        talk.mention2 = t[1]
          #      end
          #    end
          #  end
          #
          #  talk.save
          #end
          #else
          #  user.errors.each do |e,e2|
          #    puts "#{e} - #{e2}"
          #  end
          #end
        end

        #Resque.enqueue(PushDatasiftStream)
      end
    end
  end
end