# Embeddable topic snippet that holds useful (denormalized) user info
class TopicSnippet
  include Mongoid::Document

  field :name
  field :slug
  field :public_id

  # Return the users username instead of their ID
  def to_param
    self.slug
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end
end