# Embeddable core object snippet that holds useful (denormalized) core object info
class PostShare
  include Mongoid::Document
  include Limelight::Mentions

  field :content
  field :mediums, :default => {}
  field :status, :default => 'active'
  field :user_id

  attr_accessible :content

  embedded_in :post_media

  def created_at
    id.generation_time
  end

  def as_json
    {
            :id => :_id,
            :user_id => user_id,
            :content => content,
            :mediums => mediums,
            :created_at => created_at
    }
  end
end