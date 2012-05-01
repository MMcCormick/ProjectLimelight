class SourceSnippet
  include Mongoid::Document

  field :name
  field :url
  field :title
  field :content
  field :score, :default => 0
  field :video_id # for video submissions

  embedded_in :has_source, polymorphic: true
end