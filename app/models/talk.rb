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
    if !is_popular && score > 0.1 && status == 'active'
      Resque.enqueue(FeedsPopularTalk, id.to_s)
    end
  end

  def push_popular_talk
    FeedUserItem.post_create(self, true)
    FeedTopicItem.post_create(self) unless !response_to || topic_mentions.empty?
    self.is_popular = true
    save
  end
end