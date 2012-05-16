require "net/http"

class Controller
  attr_accessor :_prefixes
  def params() {} end
end

class TestingController < ApplicationController

  def test
    SendDailyUserNotifications.perform()
  end

  def facebook_thing
    fb = current_user.facebook
    og_id = fb.put_connections("me", "#{og_namespace}:follow", :profile => "http://localhost:3000/users/marc2")
    if og_id

      case action
        when 'follow'
          ll_action = ActionFollow.where(:from_id => user_id, :to_id => target_id, :action => 'create').order_by(:created_at, :desc).first
        when 'like'
          ll_action = ActionLike.where(:from_id => user_id, :to_id => target_id, :action => 'create').order_by(:created_at, :desc).first
        else
          ll_action = nil
      end

      if ll_action
        ll_action.og_id = og_id
        ll_action.save
      end

    end
  end

  def something
    #test = "Beyonce Is Peoples Most Beautiful Woman Only 3 Months After Giving Birth"
    #test2 = "RT if you think that Katy is beautiful even without any makeup"
    #alchemyObj = AlchemyApi::ConceptTagging.get_concepts_from_url()
    #alchemyObj.api_key('1deee8afa82d7ba26ce5c5c7ceda960691f7e1b8')
    #result = alchemyObj.URLGetRankedKeywords("http://io9.com/5904599/its-official-james-cameron-and-google-unveil-plans-for-asteroid+mining", AlchemyAPI::OutputMode::JSON)

    #postData = Net::HTTP.post_form(
    #        URI.parse("http://access.alchemyapi.com/calls/url/URLGetRankedConcepts"),
    #        {
    #                'url' => 'http://www.foxnews.com/scitech/2012/04/27/google-gives-rush-to-gamers/',
    #                'apikey' => '1deee8afa82d7ba26ce5c5c7ceda960691f7e1b8',
    #                'outputMode' => 'json'
    #        }
    #)
    #concepts1 = JSON.parse(postData.body)['concepts']
    #
    #postData = Net::HTTP.post_form(
    #        URI.parse("http://access.alchemyapi.com/calls/url/URLGetRankedConcepts"),
    #        {
    #                'url' => 'http://phandroid.com/2012/04/27/stop-everything-youre-doing-and-do-a-google-search-for-zerg-rush/',
    #                'apikey' => '1deee8afa82d7ba26ce5c5c7ceda960691f7e1b8',
    #                'outputMode' => 'json'
    #        }
    #)
    #concepts2 = JSON.parse(postData.body)['concepts']
    #
    #postData = Net::HTTP.post_form(
    #        URI.parse("http://access.alchemyapi.com/calls/url/URLGetRankedNamedEntities"),
    #        {
    #                'url' => 'http://online.wsj.com/article/SB10001424052702303916904577375502392129654.html',
    #                'apikey' => '1deee8afa82d7ba26ce5c5c7ceda960691f7e1b8',
    #                'outputMode' => 'json'
    #        }
    #)
    #entities1 = JSON.parse(postData.body)['entities']
    #
    #postData2 = Net::HTTP.post_form(
    #        URI.parse("http://access.alchemyapi.com/calls/url/URLGetRankedNamedEntities"),
    #        {
    #                'url' => 'http://phandroid.com/2012/04/27/stop-everything-youre-doing-and-do-a-google-search-for-zerg-rush/',
    #                'apikey' => '1deee8afa82d7ba26ce5c5c7ceda960691f7e1b8',
    #                'outputMode' => 'json'
    #        }
    #)
    #entities2 = JSON.parse(postData2.body)['entities']

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
        #tweet_content = interaction['twitter']['retweet']['text']
        tweet_content = interaction['interaction']['content']
        tweet_content.chomp!('-|_ ')
        tweet_content.strip!

        #existing_post = Post.where(:tweet_id => interaction['twitter']['retweeted']['id']).first
        url = interaction['links'].kind_of?(Array) ? interaction['links'][0]['url'] : interaction['links']['url']
        existing_post = Post.where('sources.url' => url).first
        unless !tweet_content || existing_post
          puts tweet_content

          Resque.enqueue(DatasiftPushPost, interaction, tweet_content)
        end
      end
    end

    foo = 'bar'
  end

  def convert_for_beta
    PopularityAction.delete_all()
    FeedUserItem.delete_all()
    FeedTopicItem.delete_all()
    FeedLikeItem.delete_all()
    FeedContributeItem.delete_all()

    Post.all().each do |post|
      if post.class.name != "Talk"
        post.title = post.title.gsub(/[\#]\[([0-9a-zA-Z]*)#([^\]]*)\]/, '\2')
        post.title = post.title.gsub(/[\@]\[([0-9a-zA-Z]*)#([^\]]*)\]/, '@\2')
      end
      if post.content && !post.content.blank?
        post.content = post.content.gsub(/[\#]\[([0-9a-zA-Z]*)#([^\]]*)\]/, '\2')
        post.content = post.content.gsub(/[\@]\[([0-9a-zA-Z]*)#([^\]]*)\]/, '@\2')
      end

      post.score = 0
      post.likes = []
      post.add_initial_pop

      image = post.default_image
      if image
        image = image.first if image.is_a? Array
        image = image.original.first if image
        url = image ? image.image_url : nil
        if url
          post.image_versions = 1
          post.active_image_version = 1
        end
      end

      post.save

      post.push_to_feeds
    end
    ActionLog.destroy_all(:_type => "ActionLike")
    User.update_all(:likes_count => 0, :score => 0, :image_versions => 1, :active_image_version => 1)

    Topic.all().each do |topic|
      image = topic.default_image
      if image
        topic.image_versions = 1
        topic.active_image_version = 1
      end
      topic.score = 0
      topic.save
    end

    OldPopAction.all().each do |opa|
      if opa.type.to_s == "lk"
        object = Post.find(opa.object_id)
        user = User.find(opa.user_id)
        object.add_to_likes(user)
        user.save if object.save
      end
    end

  end

end