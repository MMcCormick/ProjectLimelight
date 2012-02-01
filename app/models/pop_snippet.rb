class PopSnippet #lawsuit?
  include Mongoid::Document

  field :a, :as => :amount
  field :ot, :as => :object_type
  field :rid, :as => :root_id
  field :rt, :as => :root_type

  validates_presence_of :amount, :object_type

  attr_accessible :amount, :object_type, :id, :root_id, :root_type

  embedded_in :pop_ac_snip, polymorphic: true
end