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
end