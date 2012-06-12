require "limelight"

class Post
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include Mongoid::CachedJson
  include Limelight::Acl
  include Limelight::Mentions
  include Limelight::Popularity
  include Limelight::Images
  include ModelUtilitiesHelper
  include VideosHelper

  field :title
  field :description
  field :content

  field :status, :default => 'active'
  field :user_id
  field :response_count, :type => Integer, :default => 0 # for talks, number of comments. for link/vid/pics, number of unique users talking / commenting
  field :talking_ids, :default => [] # ids of users talking about / commenting on this (not used for talks)
  field :root_id, :type => BSON::ObjectId
  field :root_type
  field :embed_html # video embeds
  field :tweet_id
  field :standalone_tweet, :default => false
  field :pushed_users_count, :default => 0 # the number of users this post has been pushed to
  field :neo4j_id
  field :category

  embeds_many :sources, :as => :has_source, :class_name => 'SourceSnippet'

  has_many   :comments
  belongs_to :response_to, :class_name => 'Post', index: true
  belongs_to :user, index: true
  has_and_belongs_to_many :likes, :inverse_of => nil, :class_name => 'User', index: true

  validates :user, :status, :presence => true
  validate :title_length, :content_length, :unique_source

  attr_accessible :title, :content, :response_to_id, :source_name, :source_url, :source_video_id, :source_title, :source_content, :embed_html, :tweet_content, :tweet, :tweet_id, :standalone_tweet
  attr_accessor :source_name, :source_url, :source_video_id, :source_title, :source_content, :tweet_content, :tweet

  #default_scope where('status' => 'active')

  before_validation :set_source_snippet
  before_create :save_remote_image, :current_user_own, :send_tweet, :set_root
  after_create :process_images, :neo4j_create, :update_response_counts, :feed_post_create, :action_log_create, :add_initial_pop, :add_first_talk
  after_save :update_denorms
  before_destroy :disconnect

  # MBM: hot damn lots of indexes. can we do this better? YES WE CAN
  # MCM: chill out obama
  # MBM: lolz
  # MBM: YES WE DID
  index({ :root_id => -1, :_type => 1 })
  index({ :topic_mentions => -1 })
  index({ "sources.url" => 1 })

  def to_param
    id.to_s
  end

  def created_at
    id.generation_time
  end

  # short version of the contnet "foo bar foo bar..." used in notifications etc.
  def short_name
    short = name[0..30]
    if name.length > 30
      short += '...'
    end
    short
  end

  # After a root post create, if there is content then create a linked talk for the user
  def add_first_talk
    unless self.class.name == 'Talk' || content.blank?
      user.talks.create(
              :content => content,
              :response_to_id => id,
              :first_talk => true,
              :topic_mention_ids => topic_mention_ids
      )
    end
  end

  def set_source_snippet
    if (@source_name && !@source_name.blank?) || (@source_url && !@source_url.blank?) || (@source_video_id && !@source_video_id.blank?)
      source = SourceSnippet.new
      source.name = @source_name unless @source_name.blank?
      source.url = @source_url unless @source_url.blank?
      source.title = @source_title unless @source_title.blank?
      source.content = @source_content unless @source_content.blank?
      source.video_id = @source_video_id unless @source_video_id.blank?
      add_source(source)
    end
  end

  def add_initial_pop
    unless standalone_tweet
      add_pop_action(:new, :a, user)
    end
  end

  def add_source(source)
    found = sources.detect{|existing| existing.name && existing.name.parameterize == source.name.parameterize}
    unless found
      self.sources << source
    end
  end

  # if required, checks that the given post URL is valid
  def has_valid_url
    if sources.length == 0
      errors.add(:url, "is required")
    end
    if sources.length > 0 && (sources[0].url.length < 3 || sources[0].url.length > 200)
      errors.add(:url, "must be between 3 and 200 characters long")
    end
  end

  def title_length
    if title && title.length > 125
      errors.add(:title, "cannot be more than 125 characters long")
    end
  end

  def content_length
    if content && content.length > 280
      errors.add(:content, "cannot be more than 280 characters long")
    end
  end

  def unique_source
    if sources.length > 0 && !sources.first.url.blank? && !self.persisted?
      if Post.where('sources.url' => sources.first.url).first
        errors.add('Link', "has already been added to Limelight")
      end
    end
  end

  def send_tweet
    if @tweet == '1' && @tweet_content && !@tweet_content.blank? && user.twitter
      user.twitter.update(@tweet_content)
    end
  end

  # Likes
  def liked_by?(user_id)
    like_ids.include?(user_id)
  end

  def add_to_likes(user)
    unless user_id == user.id || liked_by?(user.id)
      self.likes << user
      user.likes_count += 1
      amount = add_pop_action(:lk, :a, user)
      Resque.enqueue(Neo4jPostLike, user.id.to_s, id.to_s)
      Resque.enqueue(PushLike, id.to_s, user.id.to_s)

      amount
    end
  end

  def push_like(user)
    ActionLike.create(:action => 'create', :from_id => user.id, :to_id => id, :to_type => self.class.name)
    FeedUserItem.like(user, self)
    FeedLikeItem.create(user, self)
  end

  def remove_from_likes(user)
    if liked_by?(user.id)
      self.like_ids.delete(user.id)
      user.likes_count -= 1
      add_pop_action(:lk, :r, user)
      Resque.enqueue(Neo4jPostUnlike, user.id.to_s, id.to_s)
      Resque.enqueue(PushUnlike, id.to_s, user.id.to_s)

      true
    end
  end

  def push_unlike(user)
    ActionLike.create(:action => 'destroy', :from_id => user.id, :to_id => id, :to_type => self.class.name)
    FeedUserItem.unlike(user, self)
    FeedLikeItem.destroy(user, self)
  end

  def disconnect
    # remove from neo4j
    node = Neo4j.neo.get_node_index('posts', 'uuid', id.to_s)
    Neo4j.neo.delete_node!(node)

    FeedTopicItem.post_destroy(self)
    FeedLikeItem.post_destroy(self)
    FeedContributeItem.post_destroy(self)

    # remove from popularity actions
    actions = PopularityAction.where("pop_snippets._id" => id)
    actions.each do |a|
      a.pop_snippets.find(id).delete
      a.save
    end
  end

  ##
  # RESPONSES
  ##

  #TODO: background these response count functions

  def update_response_counts(u_id=nil)
    u_id ||= user_id
    if response_to
      response_to.register_response(u_id)
    end
  end

  def register_response(u_id)
    unless talking_ids.include?(u_id)
      self.talking_ids << u_id
      self.response_count =  response_count.to_i + 1
      save
    end
  end

  def neo4j_create
    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'post', 'subtype' => self.class.name, 'created_at' => created_at.to_i, 'category' => category, 'score' => score)
    Neo4j.neo.add_node_to_index('posts', 'uuid', id.to_s, node)

    Resque.enqueue(Neo4jPostCreate, id.to_s)

    node
  end

  def action_log_create
    ActionPost.create(:action => 'create', :from_id => user_id, :to_id => id, :to_type => self.class.name)
  end

  def action_log_delete
    ActionPost.create(:action => 'delete', :from_id => user_id, :to_id => id, :to_type => self.class.name)
  end

  def feed_post_create
    Resque.enqueue(PushPostToFeeds, id.to_s)
  end

  def push_to_feeds
    FeedUserItem.push_post_through_users(self)
    FeedUserItem.push_post_through_topics(self) unless response_to_id || topic_mention_ids.empty?
    FeedTopicItem.post_create(self) unless response_to_id || topic_mention_ids.empty?
    FeedContributeItem.create(self)
  end

  def disable
    self.status = 'disabled'
    Resque.enqueue(PushPostDisable, id.to_s)
  end

  def push_disable
    FeedUserItem.post_disable(self, (self.class.name == 'Talk' && !is_popular))
    FeedTopicItem.post_disable(self) unless response_to_id || topic_mention_ids.empty?
    FeedContributeItem.disable(self)
  end

  def set_root
    if response_to_id
      self.root_id = response_to.id
      self.root_type = response_to._type
    #elsif self.class.name == 'Talk' && primary_topic_mention
    #  self.root_id = primary_topic_mention
    #  self.root_type = 'Topic'
    else
      self.root_id = id
      self.root_type = _type
    end
  end

  def is_root?
    id == root_id
  end

  def root
    root_type == 'Topic' ? Topic.find(root_id) : Post.find(root_id)
  end

  def standalone_talk?
    _type == "Talk" && !response_to_id
  end

  def og_type
    og_namespace + ":post"
  end

  def primary_source
    sources.first
  end

  ##########
  # JSON
  ##########

  def mixpanel_data(extra=nil)
    {
            "Post Type" => _type,
            "Post Score" => score,
            "Post Response Count" => response_count,
            "Post Created At" => created_at,
            "Post Is Root?" => response_to_id ? true : false,
            "Post Root Type" => response_to_id ? root_type : nil,
            "Post From Twitter?" => standalone_tweet ? true : false
    }
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :slug => { :definition => :to_param, :properties => :short, :versions => [ :v1 ] },
    :type => { :definition => :_type, :properties => :short, :versions => [ :v1 ] },
    :title => { :properties => :short, :versions => [ :v1 ] },
    :content => { :properties => :short, :versions => [ :v1 ] },
    :score => { :properties => :short, :versions => [ :v1 ] },
    :response_count => { :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => lambda { |instance| instance.created_at.to_i }, :properties => :short, :versions => [ :v1 ] },
    :created_at_pretty => { :definition => lambda { |instance| instance.pretty_time(instance.created_at) }, :properties => :short, :versions => [ :v1 ] },
    :created_at_short => { :definition => lambda { |instance| instance.short_time(instance.created_at) }, :properties => :short, :versions => [ :v1 ] },
    :video => { :definition => lambda { |instance| instance.json_video }, :properties => :short, :versions => [ :v1 ] },
    :video_autoplay => { :definition => lambda { |instance| instance.json_video(true) }, :properties => :short, :versions => [ :v1 ] },
    :images => { :definition => lambda { |instance| instance.json_images }, :properties => :short, :versions => [ :v1 ] },
    :likes => { :definition => lambda { |instance| instance.like_ids }, :properties => :short, :versions => [ :v1 ] },
    :primary_source => { :type => :reference, :definition => :primary_source, :properties => :short, :versions => [ :v1 ] },
    :user => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :topic_mentions => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :user_mentions => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :recent_likes => { :type => :reference, :definition => lambda { |instance| instance.likes.limit(5) }, :properties => :short, :versions => [ :v1 ] },
    :comments => { :type => :reference, :properties => :public, :versions => [ :v1 ] }

  def json_video(autoplay=nil)
    unless embed_html.blank?
      video_embed(sources[0], 680, 480, nil, nil, embed_html, autoplay)
    end
  end

  def json_images
    if image_versions > 0
      {
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
    # Build and return a post based on params (does not save)
    def post(params, user)
      if params[:type] && ['Video', 'Picture', 'Link', 'Talk'].include?(params[:type])
        post = Kernel.const_get(params[:type]).new(params)
        post.user = user
      else
        post = Post.new
      end
      post
    end

    def friend_responses(id, user, page, limit)
      if user
        Post.where(:root_id => id, :_type => 'Talk', "user_id" => {"$in" => user.following_users})
            .desc(:_id)
            .skip((page-1)*limit).limit(limit)
      else
        []
      end
    end

    # get the public responses for a root, with a limit
    # TODO: Cache this
    def public_responses(id, page, limit)
      Post.where(:root_id => id, :_type => 'Talk')
          .desc(:_id)
          .skip((page-1)*limit).limit(limit)
    end

    def public_responses_no_friends(id, page, limit, user)
      posts = Post.public_responses(id, page, limit)
      if user
        posts.select{|p| !user.is_following_user?(p.user_id) }
      else
        posts
      end
    end

    # returns the latest posts site wide
    def global_stream(page)
      items = Post.where(:status => 'active').desc(:_id)
      items = items.skip((page-1)*20).limit(20)

      return_objects = []
      items.each do |i|
        root_post = RootPost.new
        root_post.root = i

        root_post.public_talking = root_post.root.response_count

        #get the public responses
        root_post.public_responses = []
        unless i.root_type == 'Talk' || root_post.public_talking == 0
          root_post.public_responses = Post.public_responses(root_post.root.id, 1, 2)
        end

        return_objects << root_post
      end

      return_objects
    end

    # @example Fetch the core_objects for a feed with the given criteria
    #   Post.feed
    #
    # @param [ display_types ] Array of Post types to fetch for the feed
    # @param { order_by } Array of format { 'target' => 'field', 'order' => 'direction' } to sort the feed
    # @param { options } Options TODO: Fill out these options
    #
    # @return [ Posts ]
    def feed(feed_id, sort, page)
      items = FeedUserItem.where(:feed_id => feed_id)
      if sort == 'newest'
        items = items.desc(:last_response_time)
      else
        items = items.desc(:rel)
      end
      items = items.skip((page-1)*20).limit(20)

      build_user_feed(items)
    end

    def build_user_feed(items)
      topic_ids = []
      item_ids = []
      items.each do |i|
        if i.root_type == 'Topic'
          topic_ids << i.root_id
        else
          item_ids << i.root_id
        end
      end

      topics = {}
      posts = {}
      tmp_topics = topic_ids.length > 0 ? Topic.where(:_id => {'$in' => topic_ids}) : []
      tmp_posts = Post.where(:_id => {'$in' => item_ids})

      tmp_topics.each {|t| topics[t.id.to_s] = t}
      tmp_posts.each {|p| posts[p.id.to_s] = p }

      return_objects = []
      items.each do |i|
        root_post = RootPost.new
        root_post.push_item = i
        if i.root_type == 'Topic'
          root_post.root = topics[i.root_id.to_s]
        else
          root_post.root = posts[i.root_id.to_s]
        end

        next unless root_post.root

        #root_post.public_talking = root_post.root.response_count

        # get the public responses
        root_post.feed_responses = []
        unless i.root_type == 'Talk' || root_post.root.response_count == 0
          root_post.feed_responses = Post.public_responses(root_post.root.id, 1, 4)
        end

        return_objects << root_post
      end

      return_objects
    end

    def activity_feed(feed_id, page)
      items = FeedContributeItem.where(:feed_id => feed_id).desc(:last_response_time)
      items = items.skip((page-1)*20).limit(20)

      build_activity_feed(items)
    end

    def like_feed(feed_id, page)
      items = FeedLikeItem.where(:feed_id => feed_id).desc(:last_response_time)
      items = items.skip((page-1)*20).limit(20)

      build_like_feed(items)
    end

    def topic_feed(feed_ids, user_id, sort, page)
      items = FeedTopicItem.where(:mentions => {'$in' => feed_ids})

      if sort == 'newest'
        items = items.desc(:last_response_time)
      else
        items = items.desc(:p)
      end

      items = items.skip((page-1)*20).limit(20)
      items = items.to_a
      user_items = FeedUserItem.where(:feed_id => user_id, :root_id => {'$in' => items.map{|i| i.root_id}}).to_a
      build_topic_feed(items, user_items, feed_ids)
    end

    def build_topic_feed(items, user_items, feed_ids)
      item_ids = []
      items.each do |i|
        item_ids << i.root_id
        user_i = user_items.detect{ |ui| ui.root_id == i.root_id }
        item_ids += user_i.responses.last(2) if user_i && user_i.responses
      end

      posts = {}
      tmp_posts = Post.where(:_id => {'$in' => item_ids})

      tmp_posts.each do |p|
        if p.root_id != p.id && p.root_type != 'Topic'
          personal_responses[p.root_id.to_s] ||= []
          personal_responses[p.root_id.to_s] << p
        else
          posts[p.id.to_s] = p
        end
      end

      return_objects = []
      items.each do |i|
        root_post = RootPost.new
        root_post.root = posts[i.root_id.to_s]

        next unless root_post.root

        #root_post.personal_responses = personal_responses[root_post.root.id.to_s] ? personal_responses[root_post.root.id.to_s] : []
        #root_post.public_talking = root_post.root.response_count

        # get the public responses
        root_post.feed_responses = []
        unless i.root_type == 'Talk' || root_post.root.response_count == 0
          root_post.feed_responses = Post.public_responses(root_post.root.id, 1, 4)
        end

        return_objects << root_post
      end

      return_objects
    end

    def build_activity_feed(items)
      topic_ids = []
      item_ids = []
      items.each do |i|
        if i.root_type == 'Topic'
          topic_ids << i.root_id
        else
          item_ids << i.root_id
        end
        item_ids += i.responses if i.responses
      end

      topics = {}
      posts = {}
      activity_responses = {}
      tmp_topics = topic_ids.length > 0 ? Topic.where(:_id => {'$in' => topic_ids}) : []
      tmp_posts = Post.where(:_id => {'$in' => item_ids})

      tmp_topics.each {|t| topics[t.id.to_s] = t}
      tmp_posts.each do |p|
        if p.root_id != p.id
          activity_responses[p.root_id.to_s] ||= []
          activity_responses[p.root_id.to_s] << p
        else
          posts[p.id.to_s] = p
        end
      end

      return_objects = []
      items.each do |i|
        root_post = RootPost.new
        if i.root_type == 'Topic'
          root_post.root = topics[i.root_id.to_s]
        else
          root_post.root = posts[i.root_id.to_s]
        end

        next unless root_post.root

        root_post.activity_responses = activity_responses[root_post.root.id.to_s] ? activity_responses[root_post.root.id.to_s].reverse : []

        return_objects << root_post
      end

      return_objects
    end

    def build_like_feed(items)
      topic_ids = []
      item_ids = []
      items.each do |i|
        if i.root_type == 'Topic'
          topic_ids << i.root_id
        else
          item_ids << i.root_id
        end
        item_ids += i.responses if i.responses
      end

      topics = {}
      posts = {}
      like_responses = {}
      tmp_topics = topic_ids.length > 0 ? Topic.where(:_id => {'$in' => topic_ids}) : []
      tmp_posts = Post.where(:_id => {'$in' => item_ids})

      tmp_topics.each {|t| topics[t.id.to_s] = t}
      tmp_posts.each do |p|
        if p.root_id != p.id
          like_responses[p.root_id.to_s] ||= []
          like_responses[p.root_id.to_s] << p
        else
          posts[p.id.to_s] = p
        end
      end

      return_objects = []
      items.each do |i|
        root_post = RootPost.new
        if i.root_type == 'Topic'
          root_post.root = topics[i.root_id.to_s]
        else
          root_post.root = posts[i.root_id.to_s]
        end

        next unless root_post.root

        root_post.like_responses = like_responses[root_post.root.id.to_s] ? like_responses[root_post.root.id.to_s] : []

        return_objects << root_post
      end

      return_objects
    end
  end

  def update_denorms
    if score_changed?
      Resque.enqueue_in(10.minutes, ScoreUpdate, 'Post', id.to_s)
    end
  end

  protected

  def current_user_own
    grant_owner(user.id)
  end

end