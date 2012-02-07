class LLSoulmate

  class << self

    include Rails.application.routes.url_helpers
    include SoulmateHelper
    include TorqueBox::Messaging::Backgroundable
    always_background :create_topic, :destroy_topic, :create_user, :destroy_user, :user_follow_user, :user_unfollow_user

    def create_topic(topic)
      Soulmate::Loader.new("topic").add(topic_nugget(topic))
    end

    def destroy_topic(topic_id)
      Soulmate::Loader.new("topic").remove({'id' => topic_id.to_s})
    end

    def create_user(user)
      Soulmate::Loader.new("user").add(user_nugget(user))
    end

    def destroy_user(user_id)
      Soulmate::Loader.new("user").remove({'id' => user_id.to_s})
    end

    def user_follow_user(user1_id, user2)
      Soulmate::Loader.new(user1_id.to_s).add(user_nugget(user2))
    end

    def user_unfollow_user(user1_id, user2_id)
      Soulmate::Loader.new(user1_id.to_s).remove({'id' => user2_id.to_s})
    end
  end
end