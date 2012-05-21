class CrawlerSource
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :source_name
  field :category
  field :url
  field :last_crawled
  field :last_modified
  field :etag
  field :posts_added, :default => 0
  field :status, :default => 'active'

  attr_accessible :source_name, :category, :url

  validates :url, :uniqueness => { :case_sensitive => false, :message => 'URL is already in use!' }
end