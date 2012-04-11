# Embeddable core object snippet that holds useful (denormalized) core object info
class PostSnippet
  include Mongoid::Document

  field :name
  field :type
  field :public_id
  field :comment_id

  embedded_in :core_object_assignable, polymorphic: true

  def to_param
    "#{encoded_id}-#{name.parameterize[0..40].chomp('-')}"
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end

  # short version of the contnet "foo bar foo bar..." used in notifications etc.
  def short_name
    short = name[0..30]
    if name.length > 30
      short += '...'
    end
    short
  end

  def as_json
    {
            :id => id.to_s,
            :slug => to_param,
            :type => type,
            :public_id => public_id,
            :comment_id => comment_id
    }
  end
end