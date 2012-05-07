require 'datasift'
require "uri"

namespace :datasift do

  desc "Consume datasift stream."
  task :consume_stream => :environment do

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

    consumer.consume(true) do |interaction|
      if interaction

        # clean tweets
        tweet_content = interaction['twitter']['retweet']['text']
        #tweet_content = interaction['interaction']['content']
        tweet_content.chomp!('-|_ ')
        tweet_content.strip!

        link = interaction['links'].kind_of?(Array) ? interaction['links'][0] : interaction['links']
        existing_post = Post.any_of({'sources.url' => link['url'][0]}, {:tweet_id => interaction['twitter']['retweeted']['id']}).first
        if tweet_content && !existing_post

          puts tweet_content

          Resque.enqueue(DatasiftPushPost, interaction, tweet_content, link['url'][0])
        end
      end
    end
  end
end