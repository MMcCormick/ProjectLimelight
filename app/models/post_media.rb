require "limelight"

class PostMedia
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include Mongoid::CachedJson
  include Limelight::Acl
  include Limelight::Images
  include Limelight::Popularity
  include ModelUtilitiesHelper

  field :title
  field :description # if a link, the pulled description from the url
  field :posted_ids, :default => [] # ids of users that have posted this DEPRECATED
  field :posts_count, :default => 0 # how many reposts DEPRECATED
  field :pushed_users_count, :default => 0 # the number of users this post has been pushed to
  field :comment_count, :default => 0
  field :score, :default => 0
  field :ll_score, :default => 0
  field :tw_base, :default => 0
  field :fb_base, :default => 0
  field :google_base, :default => 0
  field :pinterest_base, :default => 0
  field :linkedin_base, :default => 0
  field :delicious_base, :default => 0
  field :stumble_base, :default => 0
  field :neo4j_id, :type => Integer
  field :status, :default => 'active'
  field :pending_images
  field :created_at, :default => Time.now

  embeds_many :sources, :as => :has_source, :class_name => 'SourceSnippet'
  embeds_many :comments, :class_name => 'CommentEmbedded'
  embeds_many :shares, :class_name => 'PostShare'

  belongs_to :user, :index => true

  has_many :posts # deprecated
  has_and_belongs_to_many :topics, :inverse_of => nil, :index => true

  validate :title_length, :unique_source
  validates :description, :length => {:maximum => 1500}

  attr_accessible :title, :source_name, :source_url, :source_video_id, :source_title, :source_content, :embed_html, :description, :pending_images
  attr_accessor :source_name, :source_url, :source_video_id, :source_title, :source_content, :individual_share

  default_scope where(:status => "active")

  before_validation :set_source_snippet
  before_create :current_user_own
  after_create :neo4j_create, :action_log_create, :process_images, :call_set_base_scores
  after_save :update_denorms, :update_shares_topics
  before_destroy :disconnect

  index({ "shares.user_id" => 1, "shares.created_at" => -1, "shares.topic_mention_ids" => 1 })
  index({ :topic_ids => 1, :_id => -1 })
  index({ :topic_ids => 1, :score => -1 })

  def to_param
    id.to_s
  end

  def name
    title
  end

  # short version of the contnet "foo bar foo bar..." used in notifications etc.
  def short_name
    return '' if title.nil? || title.blank?

    short = title[0..30]
    if title.length > 30
      short += '...'
    end
    short
  end

  def og_type
    og_namespace + ":post"
  end

  def set_source_snippet
    if @source_url && !@source_url.blank?
      source = SourceSnippet.new
      source.name = @source_name
      source.url = @source_url
      #source.title = @source_title unless @source_title.blank?
      #source.content = @source_content unless @source_content.blank?
      source.video_id = @source_video_id unless @source_video_id.blank?

      if @source_name && !@source_name.blank?
        topic = Topic.where(:slug => @source_name.parameterize).first
        unless topic
          topic = user.topics.create(:name => @source_name)
        end
        source.id = topic.id
      end

      add_source(source)
    end
  end

  def add_source(source)
    unless sources.where(:url => source.url).first
      self.sources << source
    end
  end

  # if required, checks that the given post URL is valid
  def has_valid_url
    if sources.length == 0
      errors.add(:url, "Source is required")
    end
    if sources.length > 0 && (sources[0].url.length < 3 || sources[0].url.length > 200)
      errors.add(:url, "Source URL must be between 3 and 200 characters long")
    end
  end

  def title_length
    if title && title.length > 125
      errors.add(:title, "Title cannot be more than 125 characters long")
    end
  end

  def unique_source
    if sources.length > 0 && !sources.first.url.blank? && !persisted?
      if PostMedia.where('sources.url' => sources.first.url).first
        errors.add('Link', "Source has already been added to Limelight")
      end
    end
  end

  def primary_source
    sources.first
  end

  def topic_count
    topic_ids.length
  end

  def neo4j_create
    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'post_media', 'subtype' => self.class.name, 'created_at' => created_at.to_i, 'score' => score.to_i)
    Neo4j.neo.add_node_to_index('post_media', 'uuid', id.to_s, node)

    Resque.enqueue(Neo4jPostMediaCreate, id.to_s)

    node
  end

  def user_posted(user_id)
    unless posted_ids.include?(user_id)
      self.posted_ids << user_id
      self.posts_count += 1
      save
    end
  end

  # SHARES
  def add_share(user_id, content, topic_ids=[], topic_names=[], from_bookmarklet=false)
    existing = shares.where(:user_id => user_id).first
    return existing if existing

    share = PostShare.new(:content => content, :topic_mention_ids => topic_ids, :topic_mention_names => topic_names, :from_bookmarklet => from_bookmarklet)
    share.user_id = user_id

    if share.valid?

      self.shares << share
      self.ll_score += 1
      share.set_mentions

      share.topic_mention_ids.each do |t|
        self.topic_ids << t
      end

      self.topic_ids.uniq!
    end

    share
  end

  def delete_share(user_id)
    share = get_share(user_id)
    if share
      share.topic_mentions.each do |t|
        Neo4j.update_talk_count(share.user, t, -1, nil, nil, id)
      end
      self.shares.delete(share)
      self.ll_score -= 1
      reset_topic_ids
    end
  end

  def get_share(user_id)
    shares.where(:user_id => user_id).first
  end

  # sets all shares status to active
  # sets all their topic_ids to the first two topic ids on this post if found
  def publish_shares
    self.shares.where(:status => 'publishing').each do |share|
      share.status = 'active'
      share.expire_cached_json
      share.feed_post_create
    end
  end
  # END SHARES

  # COMMENTS
  def add_comment(commenter_id, content)
    comment = CommentEmbedded.new(:content => content)
    comment.user_id = commenter_id

    self.comments << comment
    self.comment_count += 1

    comment
  end
  # END COMMENTS

  def call_set_base_scores
    #Resque.enqueue(PostSetBaseScores, id.to_s)
  end

  # calls the sharedcount api to set all the base social media counts
  def set_base_scores
    begin
      content = Yajl::Parser.parse(open("http://api.sharedcount.com/?url=#{URI.escape(primary_source.url)}").read)
      self.tw_base = content['Twitter']
      self.fb_base = content['Facebook']['share_count']
      self.google_base = content['GooglePlusOne']
      self.pinterest_base = content['Pinterest']
      self.linkedin_base = content['LinkedIn']
      self.delicious_base = content['Delicious']
      self.stumble_base = content['StumbleUpon']
    rescue => e
      return
    end
  end

  # uses a simple time decay function to calculate this posts score
  # number of shares / (t + 2) ^ 1.5 where t is the number of hours since the item was posted to limelight
  def calculate_score
    self.score = (ll_score + tw_base + fb_base + google_base + pinterest_base + linkedin_base + delicious_base + stumble_base) / (((Time.now - created_at) / 1.hour) + 2 ** 3.0)
  end

  # goes through all shares and re-calculates the topic_ids that should be on this post
  def reset_topic_ids
    topic_ids = []
    shares.each do |s|
      topic_ids += s.topic_mention_ids
    end
    self.topic_ids = topic_ids.uniq
  end

  def current_user_own
    grant_owner(user.id)
  end

  def action_log_create
    ActionPost.create(:action => 'create', :from_id => user_id, :to_id => id, :to_type => self.class.name)
  end

  def action_log_delete
    ActionPost.create(:action => 'delete', :from_id => user_id, :to_id => id, :to_type => self.class.name)
  end

  def disconnect
    # remove from user feeds
    FeedUserItem.where(:post_id => id).delete

    # remove from neo4j
    node = Neo4j.neo.get_node_index('post_media', 'uuid', id.to_s)
    Neo4j.neo.delete_node!(node)
  end

  def push_to_feeds(topic=nil)
    if topic
      FeedUserItem.push_post_through_topic(self, topic)
    else
      FeedUserItem.push_post_through_topics(self)
    end
  end

  def update_shares_topics
    if topic_ids_was != topic_ids
      removed = topic_ids_was ? topic_ids_was - topic_ids : []
      added = topic_ids_was ? topic_ids - topic_ids_was : topic_ids

      return if removed.length == 0 && added.length == 0

      # if this post has new topics and didn't have any before, add them to pending shares
      if !topic_ids_was || topic_ids_was.length == 0
        target_shares = self.shares.where(:status => 'pending')
        target_topics = Topic.where(:_id => {"$in" => topic_ids.first(2)})
        target_shares.each do |s|
          target_topics.each do |t|
            s.add_topic_mention(t)
          end
        end
      end

      # update post counts on topics
      Topic.where(:id => {"$in" => removed}).inc(:post_count, -1)
      Topic.where(:id => {"$in" => added}).inc(:post_count, 1)

      # push to new feeds
      added.each do |i|
        topic = Topic.find(i)
        if topic
          Resque.enqueue(PushPostToFeeds, id.to_s, nil, topic.id.to_s)
        end
      end

      # remove from feeds
      removed.each do |i|
        topic = Topic.find(i)
        if topic
          Resque.enqueue(UnpushPostThroughTopic, id.to_s, topic.id.to_s)
        end
      end
    end
  end

  def update_denorms
    # TODO: do we have to do this?
    #if topic_ids_changed?
    #
    #  # new topic ids?
    #  if topic_ids.length > topic_ids_was?
    #    change = topic_ids - topic_ids_was?
    #
    #
    #  # removed topic ids?
    #  else
    #    change = topic_ids_was? - topic_ids
    #
    #
    #  end
    #
    #
    #  change = topic_ids_was? - topic_ids
    #  if change.length > 0
    #
    #  end
    #end
  end

  def publish
    self.created_at = Time.now
    self.status = 'active'
  end

  ##########
  # JSON
  ##########

  def mixpanel_data(extra=nil)
    {
            "Post Type" => _type,
            "Post Shares" => ll_score,
            "Post Created At" => created_at,
    }
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :slug => { :definition => :to_param, :properties => :short, :versions => [ :v1 ] },
    :type => { :definition => :_type, :properties => :short, :versions => [ :v1 ] },
    :title => { :properties => :short, :versions => [ :v1 ] },
    :description => { :properties => :short, :versions => [ :v1 ] },
    :topic_count => { :properties => :short, :versions => [ :v1 ] },
    :share_count => { :definition => :ll_score, :properties => :short, :versions => [ :v1 ] },
    :score => { :definition => lambda { |instance| instance.score.to_i }, :properties => :short, :versions => [ :v1 ] },
    :status => { :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => lambda { |instance| instance.created_at.to_i }, :properties => :short, :versions => [ :v1 ] },
    :video => { :definition => lambda { |instance| instance.json_video }, :properties => :short, :versions => [ :v1 ] },
    :video_autoplay => { :definition => lambda { |instance| instance.json_video(true) }, :properties => :short, :versions => [ :v1 ] },
    :images => { :definition => lambda { |instance| instance.status == "pending" ? instance.pending_images : instance.json_images }, :properties => :short, :versions => [ :v1 ] },
    :share => { :definition => :individual_share, :properties => :short, :versions => [ :v1 ] },
    :shares => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :primary_source => { :type => :reference, :definition => :primary_source, :properties => :short, :versions => [ :v1 ] },
    :comments => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :topic_mentions => { :type => :reference, :definition => :topics, :properties => :short, :versions => [ :v1 ] }

  def json_video(autoplay=nil)
    unless _type != 'Video' || embed_html.blank?
      video_embed(sources[0], 680, 480, nil, nil, embed_html, autoplay)
    end
  end

  def json_images
    if images.length > 0 || !remote_image_url.blank?
      {
        :ratio => image_ratio,
        :w => image_width,
        :h => image_height,
        :original => image_url(nil, nil, nil, true),
        :fit => {
            :large => image_url(:fit, :large),
            :normal => image_url(:fit, :normal),
            :small => image_url(:fit, :small)
        },
        :square => {
            :large => image_url(:square, :large),
            :normal => image_url(:square, :normal),
            :small => image_url(:square, :small)
        }
      }
    end
  end

  ##########
  # END JSON
  ##########

  class << self

    # find a topic by slug or id
    def find_by_slug_id(id)
      if Moped::BSON::ObjectId.legal?(id)
        Topic.find(id)
      else
        Topic.where(:slug => id.parameterize).first
      end
    end

    def create_pending(user, url, comment, created_at=Time.now, medium=nil)
      # Use fetch_url to grab the url and find any existing posts
      response = fetch_url(url)
      return nil if response.nil?
      # If there's already a post
      if response[:existing]
        post = response[:existing]
      # Otherwise create a new post
      else
        response[:type] = response[:type] && ['Link','Picture','Video'].include?(response[:type]) ? response[:type] : 'Link'
        params = {:source_url => response[:url],
                  :source_name => response[:provider_name],
                  :embed_html => response[:video],
                  :title => response[:title],
                  :type => response[:type],
                  :description => response[:description],
                  :pending_images => response[:images]
        }
        post = Kernel.const_get(response[:type]).new(params)
        post.user_id = user.id
        post.status = "pending"
        post.created_at = created_at
      end

      if post && !post.get_share(user.id)

        share = post.add_share(user.id, comment)
        share.status = "pending"
        share.created_at = created_at
        share.add_medium(medium) if medium

        if post.valid?
          post.save
        else
          nil
        end
      else
        nil
      end
    end

    def create_pending_from_tweet(user, tweet)
      # Grab first url from tweet if it exists
      if tweet.urls.first
        # Remove urls from text
        comment = tweet.text
        tweet.urls.each do |u|
          comment.slice!(u.url)
        end
        url = tweet.urls.first.expanded_url
        medium = {:source => "Twitter", :id => tweet.id.to_i, :url => "https://twitter.com/#{user.twitter_handle}/statuses/#{tweet.id.to_i}"}

        create_pending(user, url, comment, tweet.created_at, medium)
      end
    end
  end

end