class TopicConnectionSnippet
  include Mongoid::Document

  field :topic_id
  field :topic_name
  field :topic_slug
  field :name
  field :user_id
  field :pull_from, :type => Boolean

  embedded_in :topic

  belongs_to :user

  validates :topic_name, :presence => true
  validates :topic_id, :presence => true
  validates :name, :presence => true
  validates :user_id, :presence => true

  attr_accessible :name, :pull_from, :opposite
end