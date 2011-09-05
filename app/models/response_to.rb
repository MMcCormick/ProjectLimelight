# Embeddable response snippet that holds useful (denormalized) user info
class ResponseTo
  include Mongoid::Document

  field :title
  field :_type

  embedded_in :core_object

end