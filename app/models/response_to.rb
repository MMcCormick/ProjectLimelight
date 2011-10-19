# Embeddable response snippet that holds useful (denormalized) user info
class ResponseTo
  include Mongoid::Document
  #TODO: callbacks on the object that was responded to which update these values

  field :title
  field :_type

  embedded_in :core_object

end