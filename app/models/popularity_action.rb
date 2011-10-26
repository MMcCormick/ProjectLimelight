class PopularityAction #lawsuit?
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type
  field :subtype
  field :user_id
  field :object_id

  embeds_many :popularity_action_snippets

  belongs_to :user

  validates_presence_of :type, :user_id, :object_id

  attr_accessible :type, :subtype, :object_id
end