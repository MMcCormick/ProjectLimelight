require "net/http"

class TestingController < ApplicationController

  def test
    @remove_count = 0
    @active_count = 0
    topics = Topic.where(:active_image_version => {'$gt' => 0})
    topics.each do |t|
      url = URI.parse("http://img.p-li.me/topics/#{t.id.to_s}/current/original.png")
      req = Net::HTTP.new(url.host, url.port)
      res = req.request_head(url.path)
      if res.code != "200"
        @remove_count += 1
        t.active_image_version = 0
        t.image_versions = 0
        t.save
      else
        @active_count += 1
      end
    end
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