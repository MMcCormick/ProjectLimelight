# Embeddable topic snippet that holds useful (denormalized) topic info
class TopicMention
  include Mongoid::Document

  @threshold = 2
  class << self; attr_accessor :threshold end


  field :name
  field :slug
  field :public_id
  field :short_name
  field :score, :default => 1

  embedded_in :topic_mentionable, polymorphic: true

  # Return the slugified name instead of its ID
  def to_param
    slug
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end
end