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

  validates_presence_of :topic_id, :topic_name, :topic_slug, :name, :user_id

  attr_accessible :name, :pull_from, :opposite
end