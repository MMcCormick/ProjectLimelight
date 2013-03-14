class SendPersonalWelcome
  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight, :unique => true

  def perform(user_id, today_or_yesterday)
    coin_toss = rand(2)

    if coin_toss == 0
      UserMailer.matt_welcome(user_id).deliver
    else
      UserMailer.marc_welcome(user_id, today_or_yesterday).deliver
    end
  end
end