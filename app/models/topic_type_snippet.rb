class TopicTypeSnippet
  include Mongoid::Document

  field :name
  field :user_id

  embedded_in :topic

  validates :user_id, :presence => true
  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }

  attr_accessible :name, :user_id, :id

  after_create :increment_topic_type_counter
  after_destroy :decrement_topic_type_counter

  protected

  def decrement_topic_type_counter
    type = TopicType.find(id)
    type.topic_count -= 1
    type.save
  end

  def increment_topic_type_counter
    type = TopicType.find(id)
    type.topic_count += 1
    type.save
  end
end