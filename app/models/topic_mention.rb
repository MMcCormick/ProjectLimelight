# Embeddable topic snippet that holds useful (denormalized) topic info
class TopicMention
  include Mongoid::Document
  include Limelight::Images

  @threshold = 2
  class << self; attr_accessor :threshold end

  field :name
  field :slug
  field :short_name
  field :score, :default => 1
  field :first_mention
  field :freebase_id
  field :use_freebase_image

  attr_accessible :name, :slug, :short_name, :score, :first_mention, :freebase_id, :use_freebase_image

  embedded_in :topic_mentionable, polymorphic: true

  # Return the slugified name instead of its ID
  def to_param
    slug
  end

  def as_json(options={})
    {
            :id => id.to_s,
            :slug => to_param,
            :type => 'Topic',
            :name => name,
            :images => Topic.json_images(self)
    }
  end
end