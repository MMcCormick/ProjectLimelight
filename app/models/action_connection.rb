class ActionConnection < ActionLog
  field :ftop, :as => :from_topic
  field :ttop, :as => :to_topic
  field :pf, :as => :pull_from, :default => false
  field :rpf, :as => :reverse_pull_from, :default => false
end