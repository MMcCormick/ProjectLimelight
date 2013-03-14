class RecalculateClout
  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight, :unique => true

  def perform
    users = User.all.asc(:score)
    num_users = users.length

    users.each_with_index do |user, i|
      user.clout = 2.5 * (i+1) / num_users + 0.5
      user.save
    end
  end
end