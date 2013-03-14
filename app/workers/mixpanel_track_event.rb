class MixpanelTrackEvent
  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight

  def perform(name, params, request_env)
    #mixpanel = Mixpanel.new(MIXPANEL_TOKEN, request_env)
    #mixpanel.track_event(name, params)
  end
end