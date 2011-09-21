class TopicType
  include Mongoid::Document
  include Mongoid::Timestamps

  # Denormalized in Topic.topic_type_snippet
  field :name
  field :user_id
  field :topic_count, :default => 0

  belongs_to :user

  validates :user_id, :presence => true
  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }

  attr_accessible :name

  # Return the topic slug instead of its ID
  def to_param
    self.name.to_url
  end
end