class ActionFollow < ActionLog

  field :tt, :as => :to_type
  field :og_id # open graph id for this action

end