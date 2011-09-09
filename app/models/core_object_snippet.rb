# Embeddable core object snippet that holds useful (denormalized) core object info
class CoreObjectSnippet
  include Mongoid::Document

  field :name
  field :type

  embedded_in :core_object_assignable, polymorphic: true

  def to_param
    self.name.to_url
  end
end