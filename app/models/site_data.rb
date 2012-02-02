class SiteData
  include Mongoid::Document

  field :name
  field :data, :default => {}

  index :name

end