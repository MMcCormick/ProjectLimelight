class SourceSnippet
  include Mongoid::Document

  field :name
  field :url
  field :video_id # for video submissions

  embedded_in :has_source, polymorphic: true
end