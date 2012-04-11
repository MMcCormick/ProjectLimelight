class Talk < Post

  field :is_popular, :default => false

  has_many :comments
  validates :content, :presence => true

  after_update :talk_is_cheap

  def name
    content
  end

  def talk_is_cheap
    if !is_popular && !response_to && score > 3 && status == 'active'
      Resque.enqueue(PushPopularTalk, id.to_s)
    end
  end

  def push_popular_talk
    FeedUserItem.post_create(self, true)
    self.is_popular = true
    save
  end
end