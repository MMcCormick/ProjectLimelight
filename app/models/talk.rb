class Talk < CoreObject

  has_many :comments
  validates :content, :presence => true

  def name
    content_clean
  end
end