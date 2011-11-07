# Embeddable response snippet that holds useful (denormalized) user info
class ResponseTo
  include Mongoid::Document
  #TODO: callbacks on the object that was responded to which update these values

  field :title
  field :type
  field :public_id

  embedded_in :core_object

  attr_accessible :title, :type, :public_id

  def to_param
    "#{encoded_id}-#{title.parameterize}"
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end

end