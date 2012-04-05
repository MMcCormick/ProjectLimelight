require "net/http"

class TestingController < ApplicationController

  def test
    connection = "facebook"
    if connection == "facebook" && current_user.auto_follow_fb # if it's facebook
      fb = current_user.facebook
      if fb
        friends = fb.get_connections("me", "friends")
        friends_uids = friends.map{|friend| friend['id']}
        registeredFriends = User.where("social_connects.uid" => {"$in" => friends_uids}, 'social_connects.provider' => 'facebook')
        registeredFriends.each do |friend|
          friend.follow_user(current_user) if friend.auto_follow_fb
          current_user.follow_user(friend) if current_user.auto_follow_fb
          current_user.save
        end
      end
    elsif connection == "twitter" && current_user.auto_follow_tw
      tw = current_user.twitter
      if tw
        follower_ids = tw.follower_ids.collection
        registeredFollowers = User.where("social_connects.uid" => {"$in" => follower_ids}, 'social_connects.provider' => 'twitter')
        registeredFollowers.each do |follower|
          follower.follow_user(current_user)
          current_user.save
        end

        following_ids = tw.friend_ids.collection.map{|id| id.to_s}
        registeredFollowing = User.where("social_connects.uid" => {"$in" => following_ids}, 'social_connects.provider' => 'twitter')
        registeredFollowing.each do |following|
          current_user.follow_user(following)
          current_user.save
        end
      end
    end
  end

  def pics
    users = User.all
    users.each do |user|
      user.image_versions = 0
      user.active_image_version = 0

      if user.fbuid
        user.use_fb_image = true
      end

      user.save
      user.update_social_denorms
    end

    #topics = Topic.where(:active_image_version => {'$gt' => 0}).to_a

    #topics = Topic.where(:active_image_version => {'$gt' => 0}).limit(30).skip(270)
    #topics.each do |topic|
    #  topic.process_version(topic.active_image_version)
    #  topic.make_image_version_current(topic.active_image_version)
    #end

    #topics = Topic.where(:active_image_version => {'$gt' => 0})
    #topics.each do |t|
    #  url = URI.parse("http://img.p-li.me/topics/#{t.id.to_s}/current/original.png")
    #  req = Net::HTTP.new(url.host, url.port)
    #  res = req.request_head(url.path)
    #  if res.code != "200"
    #    @remove_count += 1
    #    t.active_image_version = 0
    #    t.image_versions = 0
    #    t.save
    #  else
    #    @active_count += 1
    #  end
    #end
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