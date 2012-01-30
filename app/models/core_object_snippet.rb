# Embeddable core object snippet that holds useful (denormalized) core object info
class CoreObjectSnippet
  include Mongoid::Document

  field :name
  field :type
  field :public_id

  embedded_in :core_object_assignable, polymorphic: true

  def to_param
    "#{encoded_id}-#{name.parameterize[0..40].chomp('-')}"
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end
end