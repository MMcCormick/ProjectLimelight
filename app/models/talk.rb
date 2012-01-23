class Talk < CoreObject

  field :link_id, :type => BSON::ObjectId
  field :link_type

  has_many :comments
  validates :content, :presence => true

  def name
    content_clean
  end
end