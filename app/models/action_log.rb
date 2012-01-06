class ActionLog
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :a, :as => :action
  field :fid, :as => :from_id
  field :tid, :as => :to_id

end