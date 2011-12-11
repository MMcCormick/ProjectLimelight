class TopicAlias
  include Mongoid::Document

  field :name
  field :slug
  field :ooac, :default => false # one of a kind

  embedded_in :has_alias, polymorphic: true

end