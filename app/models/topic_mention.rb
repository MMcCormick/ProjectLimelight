# Embeddable topic snippet that holds useful (denormalized) topic info
class TopicMention
  include Mongoid::Document
  include Limelight::Images

  @threshold = 2
  class << self; attr_accessor :threshold end


  field :name
  field :slug
  field :public_id
  field :short_name
  field :score, :default => 1
  field :first_mention
  field :freebase_id
  field :use_freebase_image

  embedded_in :topic_mentionable, polymorphic: true

  # Return the slugified name instead of its ID
  def to_param
    slug
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end

  def as_json(options={})
    {
            :id => id.to_s,
            :slug => to_param,
            :type => 'Topic',
            :name => name,
            :public_id => public_id,
            :images => Topic.json_images(self)
    }
  end
end