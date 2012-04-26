class BetaSignupEmail
  include Resque::Plugins::UniqueJob

  @queue = :slow

  def self.perform(email)
    UserMailer.beta_signup_email(email).deliver
  end
end