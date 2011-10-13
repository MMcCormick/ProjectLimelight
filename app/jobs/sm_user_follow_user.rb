require 'json'

#TODO: We need to update the soulmate data when relevant user data changes (username, main image, etc)
class SmUserFollowUser
  include Resque::Plugins::UniqueJob
  include Rails.application.routes.url_helpers
  include ImageHelper

  @queue = :soulmate_user

  def initialize(user, following)
    nugget = {
              'id' => following.id.to_s,
              'term' => following.username,
              'score' => 1,
              'data' => {
                      'url' => user_path(following)
              }}

    img = default_image_url(following, [25, 25])
    nugget['data']['image'] = img[:url] if img

    nugget['data']['name'] = following.fullname if following.fullname

    Soulmate::Loader.new("#{user.username}f").add(nugget)
  end

  def self.perform(user_id, following_user_id)
    user = User.find(user_id)
    following = User.find(following_user_id)
    new(user, following) if user && following
  end
end