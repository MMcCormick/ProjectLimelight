# Embeddable core object snippet that holds useful (denormalized) core object info
# TODO: decide if this is necessary with the new notifications system
class CoreObjectSnippet
  include Mongoid::Document

  field :name
  field :type

  embedded_in :core_object_assignable, polymorphic: true

  def to_param
    self.name.to_url
  end
end