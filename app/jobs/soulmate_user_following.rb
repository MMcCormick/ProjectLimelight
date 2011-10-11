require 'json'

class SoulmateUserFollowing
  include Resque::Plugins::UniqueJob
  include Rails.application.routes.url_helpers
  include ImageHelper

  @queue = :soulmate_user

  def initialize(user, following)
    soulmate_data = Array.new
    following.each do |following_user|
      nugget = {
                'id' => following_user.id.to_s,
                'term' => following_user.username,
                'score' => 0,
                'data' => {
                        'url' => user_path(following_user)
                }}

      img = default_image_url(following_user, [30, 30])
      if img
        nugget['data']['image'] = img[:url]
      end
      soulmate_data << nugget
    end
    Soulmate::Loader.new("u#{user.username}").load(soulmate_data)
  end

  def self.perform(user_id)
    user = User.find(user_id)
    if user.following_users_count > 0
      following = User.where(:_id.in => user.following_users)
      new(user, following)
    end
  end
end