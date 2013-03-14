class AutoFollow
  include Sidekiq::Worker
  sidekiq_options :queue => :fast_limelight

  def perform(user_id, provider)
    user = User.find(user_id)
    user.auto_follow(provider)
  end
end