class TopicTypeSnippet
  include Mongoid::Document

  field :name
  field :user_id

  embedded_in :topic

  validates :user_id, :presence => true
  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }

  attr_accessible :name

  # Return the topic slug instead of its ID
  def to_param
    self.name.to_url
  end
end