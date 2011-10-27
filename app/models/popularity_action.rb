class PopularityAction #lawsuit?
  include Mongoid::Document
  include Mongoid::Timestamps

  field :t, :as => :type
  field :st, :as => :subtype
  field :uid, :as => :user_id
  field :oid, :as => :object_id

  embeds_many :pop_snippets, :as => :pop_ac_snip

  belongs_to :user

  validates_presence_of :type, :user_id, :object_id

  attr_accessible :type, :subtype, :object_id
end