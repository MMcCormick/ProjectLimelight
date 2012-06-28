require "limelight"

class Post
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include Mongoid::CachedJson
  include Limelight::Acl
  include Limelight::Mentions
  include Limelight::Popularity
  include Limelight::Throttle
  include Limelight::Images # deprecated
  include ModelUtilitiesHelper

  field :content

  field :_type # deprecated
  field :root_type # deprecated
  field :title # deprecated
  field :description # deprecated
  field :response_to_id
  field :category
  field :pushed_users_count, :default => 0 # the number of users this post has been pushed to
  field :neo4j_id
  field :response_count # deprecated
  field :comment_count, :default => 0

  field :status, :default => 'active'

  embeds_many :sources, :as => :has_source, :class_name => 'SourceSnippet' #deprecated

  has_many   :comments
  belongs_to :post_media, :class_name => 'PostMedia'
  #belongs_to :response_to, :class_name => 'Post', index: true deprecated
  belongs_to :user, :index => true
  has_and_belongs_to_many :likes, :inverse_of => nil, :class_name => 'User', :index => true

  validates :user, :status, :presence => true
  validate :content_length

  attr_accessible :content

  #default_scope where('status' => 'active')

  before_create :current_user_own
  after_create :neo4j_create, :update_response_counts, :feed_post_create, :action_log_create, :add_initial_pop, :update_user_topic_activity
  after_save :update_denorms
  before_destroy :disconnect

  def to_param
    id.to_s
  end

  def created_at
    id.generation_time
  end

  def name
    content
  end

  # short version of the contnet "foo bar foo bar..." used in notifications etc.
  def short_name
    return '' if name.nil? || name.blank?

    short = name[0..30]
    if name.length > 30
      short += '...'
    end
    short
  end

  def add_initial_pop
    return unless status == 'active'
    add_pop_action(:new, :a, user)
  end

  def content_length
    if !post_media_id || !post_media
      if content.length == 0
        errors.add(:content, "You must paste a link or talk about something")
      end
    end
    if content && content.length > 280
      errors.add(:content, "Content cannot be more than 280 characters long")
    end
  end

  def send_tweet
    if @tweet == '1' && @tweet_content && !@tweet_content.blank? && user.twitter
      user.twitter.update(@tweet_content)
    end
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

  # Likes
  def liked_by?(user_id)
    like_ids.include?(user_id)
  end

  def add_to_likes(add_user)
    unless user_id == add_user.id || liked_by?(add_user.id)
      self.likes << add_user
      add_user.likes_count += 1
      amount = add_pop_action(:lk, :a, add_user)

      Resque.enqueue(Neo4jPostLike, add_user.id.to_s, id.to_s)
      Resque.enqueue(PushLike, id.to_s, add_user.id.to_s)

      unless topic_mention_ids.empty?
        topic_mention_ids.each do |t|
          add_user.topic_likes_add(t)
        end
      end

      amount
    end
  end

  def push_like(user)
    ActionLike.create(:action => 'create', :from_id => user.id, :to_id => id, :to_type => self.class.name)
    FeedLikeItem.create(user, self)
  end

  def remove_from_likes(remove_user)
    if liked_by?(remove_user.id)
      self.like_ids.delete(remove_user.id)
      remove_user.likes_count -= 1
      add_pop_action(:lk, :r, remove_user)
      Resque.enqueue(Neo4jPostUnlike, remove_user.id.to_s, id.to_s)
      Resque.enqueue(PushUnlike, id.to_s, remove_user.id.to_s)

      unless topic_mention_ids.empty?
        topic_mention_ids.each do |t|
          remove_user.topic_likes_subtract(t)
        end
      end

      true
    end
  end

  def push_unlike(user)
    ActionLike.create(:action => 'destroy', :from_id => user.id, :to_id => id, :to_type => self.class.name)
    FeedLikeItem.destroy(user, self)
  end

  def initialize_media(params)
    return if (!params[:post_media_id] || params[:post_media_id].blank?) && !['Link','Picture','Video'].include?(params[:type])

    media = params[:post_media_id] ? PostMedia.find(params[:post_media_id]) : nil
    unless media
      params[:type] = params[:type] && ['Link','Picture','Video'].include?(params[:type]) ? params[:type] : 'Link'
      media = Kernel.const_get(params[:type]).new(params)
      media.user = user
    end

    # hijack this post if it was originally submitted by limelight
    if media.user_id.to_s == User.limelight_user_id && user_id.to_s != User.limelight_user_id
      media.user_id = user_id
      media.posted_ids = []
      media.posts_count = 0
      media.save
    end

    self.post_media = media if media
  end

  ##
  # RESPONSES
  ##

  def update_response_counts(u_id=nil)
    u_id ||= user_id
    if post_media
      post_media.user_posted(u_id)
    end
  end

  def neo4j_create
    return unless status == 'active'

    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'post', 'created_at' => created_at.to_i, 'score' => score.to_i)
    Neo4j.neo.add_node_to_index('posts', 'uuid', id.to_s, node)

    Resque.enqueue(Neo4jPostCreate, id.to_s)

    node
  end

  def action_log_create
    return unless status == 'active'
    ActionPost.create(:action => 'create', :from_id => user_id, :to_id => id, :to_type => self.class.name)
  end

  def action_log_delete
    ActionPost.create(:action => 'delete', :from_id => user_id, :to_id => id, :to_type => self.class.name)
  end

  def feed_post_create
    return unless status == 'active'
    Resque.enqueue(PushPostToFeeds, id.to_s)
  end

  def push_to_feeds
    FeedUserItem.push_post_through_users(self)
    FeedUserItem.push_post_through_topics(self)
    FeedTopicItem.post_create(self) unless topic_mention_ids.empty? && !post_media_id
    FeedContributeItem.create(self)
  end

  # does this post start with a user mention?
  def personal_mention?
    user_mention_ids.length > 0 && content.strip[0] == '@'
  end

  #def disable
  #  self.status = 'disabled'
  #  Resque.enqueue(PushPostDisable, id.to_s)
  #end
  #
  #def push_disable
  #  FeedUserItem.post_disable(self, (self.class.name == 'Talk' && !is_popular))
  #  FeedTopicItem.post_disable(self) unless response_to_id || topic_mention_ids.empty?
  #  FeedContributeItem.disable(self)
  #end

  def root_id
    post_media_id ? post_media_id : id
  end

  def root_type
    post_media ? post_media._type : 'Post'
  end

  def is_root?
    post_media_id ? false : true
  end
  #
  #def root
  #  root_type == 'Topic' ? Topic.find(root_id) : Post.find(root_id)
  #end
  #
  #def standalone_talk?
  #  _type == "Talk" && !response_to_id
  #end

  def og_type
    og_namespace + ":post"
  end

  # updates the user topic activity hash (keeps track of the # of times a user has talked about various topics)
  def update_user_topic_activity
    return unless status == 'active'
    user.posts_count += 1
    unless topic_mention_ids.empty?
      topic_mention_ids.each do |t|
        user.topic_activity_add(t)
      end
    end
    user.save
  end

  ##########
  # JSON
  ##########

  def mixpanel_data(extra=nil)
    {
            #"Post Score" => score,
            #"Post Response Count" => response_count,
            "Post Created At" => created_at,
            "Post Has Media?" => post_media_id ? true : false,
            "Post Root Type" => post_media_id ? post_media._type : nil
    }
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :slug => { :definition => :to_param, :properties => :short, :versions => [ :v1 ] },
    :type => { :definition => lambda { |instance| 'Post' }, :properties => :short, :versions => [ :v1 ] },
    :content => { :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => lambda { |instance| instance.created_at.to_i }, :properties => :short, :versions => [ :v1 ] },
    :likes => { :definition => lambda { |instance| instance.like_ids }, :properties => :short, :versions => [ :v1 ] },
    :user => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :topic_mentions => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :user_mentions => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :recent_likes => { :type => :reference, :definition => lambda { |instance| instance.likes.limit(5) }, :properties => :short, :versions => [ :v1 ] },
    :comment_count => { :properties => :short, :versions => [ :v1 ] },
    :media => { :definition => :post_media, :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :comments => { :type => :reference, :properties => :public, :versions => [ :v1 ] }

  ##########
  # END JSON
  ##########


  class << self
    def friend_responses(id, user, page, limit)
      if user
        Post.where(:root_id => id, :_type => 'Talk', "user_id" => {"$in" => user.following_users}).desc(:_id).skip((page-1)*limit).limit(limit)
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
        root_post.post = i
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
      items = items.skip((page-1)*20).limit(20).to_a

      build_user_feed(items)
    end

    def build_user_feed(items)
      item_ids = items.map {|i| i.root_type == 'Post' ? i.root_id : i.responses.last }

      posts = {}
      tmp_posts = Post.where(:_id => {'$in' => item_ids})
      tmp_posts.each {|p| posts[p.id.to_s] = p }

      return_objects = []
      items.each do |i|
        root_post = RootPost.new
        root_post.push_item = i

        if i.root_type == 'Post'
          root_post.post = posts[i.root_id.to_s]
        else
          root_post.post = posts[i.responses.last.to_s]
        end

        next unless root_post.post

        #root_post.public_talking = root_post.root.response_count

        return_objects << root_post
      end

      return_objects
    end

    def activity_feed(feed_id, page, topic=nil)

      if topic
        items = FeedContributeItem.where(:feed_id => feed_id, :topic_ids => topic.id)
      else
        items = FeedContributeItem.where(:feed_id => feed_id)
      end

      items = items.desc(:last_response_time)
      items = items.skip((page-1)*20).limit(20)

      build_activity_feed(items)
    end

    def like_feed(feed_id, page, topic=nil)
      if topic
        items = FeedLikeItem.where(:feed_id => feed_id, :topic_ids => topic.id)
      else
        items = FeedLikeItem.where(:feed_id => feed_id)
      end
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

      build_topic_feed(items)
    end

    def build_topic_feed(items)
      post_ids = []
      media_ids = []
      items.each do |i|
        if i.root_type == 'Post'
          post_ids << i.root_id
        else
          media_ids << i.root_id
        end
      end

      posts = {}
      tmp_posts = Post.where(:_id => {'$in' => post_ids})
      tmp_posts.each {|p| posts[p.id.to_s] = p }
      media = {}
      tmp_media = PostMedia.where(:_id => {'$in' => media_ids})
      tmp_media.each {|p| media[p.id.to_s] = p }

      return_objects = []
      items.each do |i|
        root_post = RootPost.new

        if i.root_type == 'Post'
          root_post.post = posts[i.root_id.to_s]
        else
          root_post.post = Post.where(:post_media_id => i.root_id).first
        end

        next unless root_post.post

        #root_post.public_talking = root_post.root.response_count

        return_objects << root_post
      end

      return_objects
    end

    def build_activity_feed(items)
      item_ids = items.map {|i| i.root_type == 'Post' ? i.root_id : i.responses.last }

      posts = {}
      tmp_posts = Post.where(:_id => {'$in' => item_ids})
      tmp_posts.each {|p| posts[p.id.to_s] = p }

      return_objects = []
      items.each do |i|
        root_post = RootPost.new

        if i.root_type == 'Post'
          root_post.post = posts[i.root_id.to_s]
        else
          root_post.post = posts[i.responses.last.to_s]
        end

        next unless root_post.post

        #root_post.public_talking = root_post.root.response_count

        return_objects << root_post
      end

      return_objects
    end

    def build_like_feed(items)
      item_ids = items.map {|i| i.root_type == 'Post' ? i.root_id : i.responses.last }

      posts = {}
      tmp_posts = Post.where(:_id => {'$in' => item_ids})
      tmp_posts.each {|p| posts[p.id.to_s] = p }

      return_objects = []
      items.each do |i|
        root_post = RootPost.new

        if i.root_type == 'Post'
          root_post.post = posts[i.root_id.to_s]
        else
          root_post.post = posts[i.responses.last.to_s]
        end

        next unless root_post.post

        #root_post.public_talking = root_post.root.response_count

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