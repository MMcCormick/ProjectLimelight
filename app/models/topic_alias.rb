class TopicAlias
  include Mongoid::Document

  field :name
  field :slug

  embedded_in :has_alias, polymorphic: true

end