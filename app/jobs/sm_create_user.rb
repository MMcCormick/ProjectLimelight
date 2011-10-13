require 'json'

#TODO: We need to update the soulmate data when relevant user data changes (username, main image, etc)
class SmCreateUser
  include Resque::Plugins::UniqueJob
  include Rails.application.routes.url_helpers
  include ImageHelper

  @queue = :soulmate_user

  def initialize(user)
    nugget = {
              'id' => user.id.to_s,
              'term' => user.username,
              'score' => 0,
              'data' => {
                      'url' => user_path(user)
              }
    }

    img = default_image_url(user, [25, 25])
    nugget['data']['image'] = img[:url] if img

    Soulmate::Loader.new("user").add(nugget)
  end

  def self.perform(user_id)
    user = User.find(user_id)
    new(user) if user
  end
end