# Embeddable core object snippet that holds useful (denormalized) core object info
class PostShare
  include Mongoid::Document
  include Mongoid::CachedJson
  include Limelight::Mentions

  field :content
  field :mediums, :default => {}
  field :status, :default => 'active'
  field :from_bookmarklet, :default => false
  field :mediums, :default => []

  attr_accessible :content, :mediums, :from_bookmarklet

  belongs_to :user
  embedded_in :post_media

  after_create :update_user_share, :neo4j_create, :feed_post_create
  after_save :check_status

  def created_at
    id.generation_time
  end

  def update_user_share
    if status == "active"
      user.share_count += 1
      topic_mention_ids.each do |tid|
        user.topic_activity_add(tid)
      end
      user.save
    end
  end

  def feed_post_create
    return unless status == 'active'
    Resque.enqueue(PushPostToFeeds, _parent.id.to_s, user_id.to_s)
  end

  def push_to_feeds
    FeedUserItem.push_post_through_users(_parent, user)
    FeedUserItem.push_post_through_topics(_parent)
  end

  def neo4j_create
    Resque.enqueue(Neo4jShareCreate, _parent.id.to_s, user_id.to_s)
  end

  def add_medium(medium)
    self.mediums << medium
  end

  # if the status changed from pending to active, push it out to feeds
  def check_status
    if status_was && status_was != status
      if status_was == 'pending' && status == 'active'
        feed_post_create
      end
    end
  end

  ##########
  # JSON
  ##########

  def mixpanel_data(extra=nil)
    {
        "From Bookmarklet?" => from_bookmarklet,
    }
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :user_id => { :properties => :short, :versions => [ :v1 ] },
    :status => { :properties => :short, :versions => [ :v1 ] },
    :content => { :properties => :short, :versions => [ :v1 ] },
    :mediums => { :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => :created_at, :properties => :short, :versions => [ :v1 ] },
    :topic_mentions => { :type => :reference, :definition => :topic_mentions, :properties => :short, :versions => [ :v1 ] }

end