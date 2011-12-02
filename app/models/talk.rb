class Talk < CoreObject

  field :comments_count, :default => 0
  has_many :comments
  validates :content, :presence => true

  def name
    content_clean
  end
end