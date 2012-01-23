class Talk < CoreObject

  has_many :comments
  validates :content, :presence => true

  after_create :send_mention_notifications

  def name
    content_clean
  end
end