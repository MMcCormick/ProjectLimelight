class TopicType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  # Denormalized in Topic.topic_type_snippet
  field :name
  field :user_id
  field :topic_count, :default => 0

  slug :name

  belongs_to :user

  validates :user_id, :presence => true
  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }

  attr_accessible :name

  after_destroy :update_topic_type_counter

  # Return the topic slug instead of its ID
  def to_param
    self.name.to_url
  end

  protected

  def update_topic_type_counter
    type = TopicType.find(id)
    type.topic_count -= 1
    type.save
  end
end