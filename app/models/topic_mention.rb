# Embeddable topic snippet that holds useful (denormalized) topic info
class TopicMention
  include Mongoid::Document

  field :name

  embedded_in :topic_mentionable, polymorphic: true

end