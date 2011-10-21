class TopicType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  # TODO: create callback
  # Denormalized in Topic.topic_type_snippet
  field :name
  field :user_id
  field :topic_count, :default => 0

  slug :name

  belongs_to :user

  validates :user_id, :presence => true
  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }

  attr_accessible :name

  # Return the topic type slug instead of its ID
  def to_param
    self.slug
  end
end