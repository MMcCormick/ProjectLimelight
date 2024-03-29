class MixpanelTrackEvent
  @queue = :slow_limelight

  def self.perform(name, params, request_env)
    mixpanel = Mixpanel.new(MIXPANEL_TOKEN, request_env)
    mixpanel.track_event(name, params)
  end
end