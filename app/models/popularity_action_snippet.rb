class PopularityActionSnippet #lawsuit?
  include Mongoid::Document

  field :a, :as => :amount
  field :ot, :as => :object_type
  field :oid, :as => :object_id

  validates_presence_of :amount, :object_id, :object_type

  attr_accessible :amount, :object_id, :object_type

  embedded_in :popularity_action
end