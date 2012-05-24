# Embeddable topic snippet that holds useful (denormalized) user info
class TopicSnippet
  include Mongoid::Document
  include Limelight::Images

  field :name
  field :slug
  field :public_id
  field :freebase_id
  field :use_freebase_image

  # Return the users username instead of their ID
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