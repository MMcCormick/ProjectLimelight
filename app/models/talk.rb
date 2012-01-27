class Talk < CoreObject

  field :is_popular, :default => false

  has_many :comments
  validates :content, :presence => true

  after_create :send_mention_notifications
  after_update :talk_is_cheap

  def name
    content_clean
  end

  def talk_is_cheap
    if !is_popular && pw > 1
      FeedUserItem.post_create(self, true)
      self.is_popular = true
      save
    end
  end
end