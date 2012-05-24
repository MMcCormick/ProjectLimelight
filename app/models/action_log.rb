class ActionLog
  include Mongoid::Document

  field :a, :as => :action
  field :fid, :as => :from_id
  field :tid, :as => :to_id

  index(
    [
      [ :_type, Mongo::DESCENDING ],
      [ :fid, Mongo::DESCENDING ],
      [ :tid, Mongo::DESCENDING ],
      [ :a, Mongo::DESCENDING ]
    ]
  )

end