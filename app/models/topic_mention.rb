# Embeddable topic snippet that holds useful (denormalized) topic info
class TopicMention
  include Mongoid::Document

  field :name
  field :slug
  field :public_id
  field :ooc, :default => false, :type => Boolean # wether the topic was mentioned out of context

  embedded_in :topic_mentionable, polymorphic: true

  # Return the slugified name instead of its ID
  def to_param
    slug
  end
end