require "limelight"

class Post
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Mentions
  include Limelight::Popularity
  include Limelight::Images
  include ModelUtilitiesHelper
  include VideosHelper

  cache

  # Denormilized:
  # Notification.object
  #TODO: bug: each core object type currently validates the length of content, but after creation content_raw is copied to content.
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
  field :pushed_users, :default => [] # the users this post has been pushed to
  field :pushed_users_count, :default => 0 # the number of users this post has been pushed to
  field :neo4j_id
  field :category

  auto_increment :public_id

  embeds_one :user_snippet, :as => :user_assignable, :class_name => 'UserSnippet'
  embeds_one :response_to, :as => :core_object_assignable, :class_name => 'PostSnippet'
  embeds_many :sources, :as => :has_source, :class_name => 'SourceSnippet'
  embeds_many :likes, :as => :user_assignable, :class_name => 'UserSnippet'

  belongs_to :user

  validates :user_id, :status, :presence => true
  validate :title_length, :content_length, :unique_source

  attr_accessible :title, :content, :parent, :parent_id, :source_name, :source_url, :source_video_id, :source_title, :source_content, :embed_html, :tweet_content, :tweet, :tweet_id, :standalone_tweet
  attr_accessor :parent, :parent_id, :source_name, :source_url, :source_video_id, :source_title, :source_content, :tweet_content, :tweet

  default_scope where('status' => 'active')

  before_validation :set_source_snippet
  before_create :save_remote_image, :denormalize_user, :current_user_own, :send_tweet, :set_response_to, :set_root
  after_create :process_images, :neo4j_create, :update_response_counts, :feed_post_create, :action_log_create, :add_initial_pop, :add_first_talk
  after_save :update_denorms

  # MBM: hot damn lots of indexes. can we do this better? YES WE CAN
  # MCM: chill out obama
  # MBM: lolz
  # MBM: YES WE DID
  index [[ :public_id, Mongo::DESCENDING ]]
  index (
    [
      [ :root_id, Mongo::DESCENDING ],
      [ :_type, Mongo::DESCENDING ],
      [ :created_at, Mongo::DESCENDING ]
    ]
  )
  index "topic_mentions"
  index "user_mentions"
  index "likes"
  index "sources"
  index(
      [
        [ :user_id, Mongo::DESCENDING ],
        [ "likes", Mongo::DESCENDING ]
      ]
    ) # used in FeedUserItem

  def to_param
    id.to_s
    #"#{encoded_id}-#{name.parameterize[0..40].chomp('-')}"
  end

  def encoded_id
    public_id.to_i.to_s(36)
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
              :parent => self,
              :first_talk => true,
              :mention1 => mention1,
              :mention2 => mention2,
              :mention1_id => mention1_id,
              :mention2_id => mention2_id,
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
    found = sources.detect{|existing| existing.name && existing.name.to_url == source.name.to_url}
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
    elsif sources.length > 0 && sources.first.url.blank?
      sources = nil
    end
  end

  def add_mention

  end

  def remove_mention(topic)
    mention = self.topic_mentions.find(topic.id)
    if mention
      mention.delete
      FeedUserItem.unpush_post_through_topic(self, topic)
      FeedTopicItem.unpush_post_through_topic(self, topic)
      Neo4j.post_remove_topic_mention(self, topic)
    end
  end

  def send_tweet
    if @tweet == '1' && @tweet_content && !@tweet_content.blank? && user.twitter
      user.twitter.update(@tweet_content)
    end
  end

  # Likes
  def liked_by?(user_id)
    likes.where(:_id => user_id).first
  end

  def add_to_likes(user)
    like = liked_by? user.id
    if like
      false
    elsif user_id == user.id
      nil
    else
      like = self.likes.new(user.attributes.merge({:fbuid => user.fbuid, :twuid => user.twuid, :use_fb_image => user.use_fb_image}))
      like.id = user.id
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
    like = liked_by? user.id
    if like
      like.destroy
      user.likes_count -= 1
      add_pop_action(:lk, :r, user)
      Resque.enqueue(Neo4jPostUnlike, user.id.to_s, id.to_s)
      Resque.enqueue(PushUnlike, id.to_s, user.id.to_s)

      true
    else
      false
    end
  end

  def push_unlike(user)
    ActionLike.create(:action => 'destroy', :from_id => user.id, :to_id => id, :to_type => self.class.name)
    FeedUserItem.unlike(user, self)
    FeedLikeItem.destroy(user, self)
  end

  ##
  # RESPONSES
  ##

  def set_response_to
    if parent || !parent_id.blank?
      unless parent
        self.parent = Post.find(parent_id)
      end
      if parent
        self.response_to = PostSnippet.new(:name => parent.title, :type => parent._type, :public_id => parent.public_id)
        self.response_to.id = parent.id
      end
    end
  end

  #TODO: background these response count functions

  def update_response_counts(u_id=nil)
    u_id ||= user_snippet.id
    if response_to
      parent ||= Post.find(response_to.id)
      parent.register_response(u_id)
    end
    register_topic_responses(u_id)
  end

  def register_response(u_id)
    unless talking_ids.include?(u_id)
      self.talking_ids << u_id
      self.response_count =  response_count.to_i + 1
      save
    end
  end

  def register_topic_responses(u_id)
    mentioned_topics.each do |topic|
      unless topic.talking_ids.include?(u_id)
        topic.talking_ids << u_id
        topic.response_count += 1
        topic.save
      end
    end
  end

  def neo4j_create
    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'post', 'subtype' => self.class.name, 'created_at' => created_at.to_i, 'category' => category, 'score' => score)
    Neo4j.neo.add_node_to_index('posts', 'uuid', id.to_s, node)

    Resque.enqueue(Neo4jPostCreate, id.to_s)

    node
  end

  def action_log_create
    ActionPost.create(:action => 'create', :from_id => user_snippet.id, :to_id => id, :to_type => self.class.name)
  end

  def action_log_delete
    ActionPost.create(:action => 'delete', :from_id => user_snippet.id, :to_id => id, :to_type => self.class.name)
  end

  def feed_post_create
    Resque.enqueue(PushPostToFeeds, id.to_s)
  end

  def push_to_feeds
    FeedUserItem.push_post_through_users(self)
    FeedUserItem.push_post_through_topics(self) unless response_to || topic_mentions.empty?
    FeedTopicItem.post_create(self) unless response_to || topic_mentions.empty?
    FeedContributeItem.create(self)
  end

  def disable
    self.status = 'disabled'
    Resque.enqueue(PushPostDisable, id.to_s)
  end

  def push_disable
    FeedUserItem.post_disable(self, (self.class.name == 'Talk' && !is_popular))
    FeedTopicItem.post_disable(self) unless response_to || topic_mentions.empty?
    FeedContributeItem.disable(self)
  end

  def set_root
    if response_to
      self.root_id = response_to.id
      self.root_type = response_to.type
    elsif self.class.name == 'Talk' && primary_topic_mention
      self.root_id = primary_topic_mention
      self.root_type = 'Topic'
    else
      self.root_id = id
      self.root_type = _type
    end
  end

  def is_root?
    id == root_id
  end

  def root
    if root_type == 'Topic'
      Topic.find(root_id)
    else
      Post.find(root_id)
    end
  end

  def standalone_talk?
    _type == "Talk" && !response_to
  end

  def og_type
    og_namespace + ":post"
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
            "Post Is Root?" => response_to ? true : false,
            "Post Root Type" => response_to ? root_type : nil,
            "Post From Twitter?" => standalone_tweet ? true : false
    }
  end

  def as_json(options={})
    data = {
            :id => id.to_s,
            :slug => to_param,
            :type => _type,
            :title => title,
            :content => content,
            :score => score,
            :talking_count => response_count,
            :liked => options[:user] && liked_by?(options[:user].id) ? true : false,
            :created_at => created_at.to_i,
            :created_at_pretty => pretty_time(created_at),
            :created_at_short => short_time(created_at),
            :video => json_video,
            :video_autoplay => json_video(true),
            :primary_source => sources.first,
            :topic_mentions => topic_mentions.map {|m| m.as_json },
            :images => json_images,
            :user => user.as_json,
            :likes_count => likes.length,
            :likes => likes.last(5).map {|u| u.as_json}
    }

    if options[:comment_threads] && options[:comment_threads][id.to_s]
      data[:comments] = options[:comment_threads][id.to_s].map {|c| c.as_json}
    else
      data[:comments] = []
    end

    data
  end

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
    def find_by_encoded_id(id)
      where(:public_id => id.to_i(36)).first
    end

    # Build and return a post based on params (does not save)
    def post(params, user_id)
      if params[:type] && ['Video', 'Picture', 'Link', 'Talk'].include?(params[:type])
        post = Kernel.const_get(params[:type]).new(params)
        post.user_id = user_id
      else
        post = Post.new
      end
      post
    end

    # Find potential news story overlap in the past X hours
    def find_similar(topics)
      posts = Post.where("topic_mentions._id" => {"$in" => topics.map{|t| t.id}}, :created_at.gte => Chronic.parse('1 hour ago'))
      chosen = nil
      posts.each do |p|
        t_ids = p.topic_mentions.map {|t| t.id.to_s}
        topic_overlap = topics.select{|t| t_ids.include?(t.id.to_s)}

        # facebook/twitter are in so many posts, never combine them
        skippers = topics.detect{|t| ['facebook','twitter'].include?(t.name.downcase)}

        if topic_overlap.length == t_ids.length && t_ids.length >= 2 && !skippers
          chosen = p
          break
        end
      end

      chosen ? chosen : nil
    end

    def friend_responses(id, user, page, limit)
      if user
        Post.where(:root_id => id, :_type => 'Talk', "user_snippet._id" => {"$in" => user.following_users})
            .order_by(:created_at, :desc)
            .skip((page-1)*limit).limit(limit)
      else
        []
      end
    end

    # get the public responses for a root, with a limit
    # TODO: Cache this
    def public_responses(id, page, limit)
      Post.where(:root_id => id, :_type => 'Talk')
          .order_by(:created_at, :desc)
          .skip((page-1)*limit).limit(limit)
    end

    def public_responses_no_friends(id, page, limit, user)
      posts = Post.public_responses(id, page, limit)
      if user
        posts.select{|p| !user.is_following_user?(p.user_snippet.id) }
      else
        posts
      end
    end

    def for_show_page(parent_id)
      Post.where(:root_id => parent_id).order_by(:created_at, :desc)
    end

    # returns the latest posts site wide
    def global_stream(page)
      items = Post.where(:status => 'active').order_by(:created_at, :desc)
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
    def feed(feed_id, display_types, sort, page)

      if display_types.include?('Talk')
        display_types << 'Topic'
      end

      items = FeedUserItem.where(:feed_id => feed_id, :root_type => {'$in' => display_types.uniq})
      if sort == 'newest'
        items = items.order_by(:last_response_time, :desc)
      else
        items = items.order_by(:rel, :desc)
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
        item_ids += i.responses.last(2) if i.responses
      end

      topics = {}
      posts = {}
      personal_responses = {}
      tmp_topics = topic_ids.length > 0 ? Topic.where(:_id => {'$in' => topic_ids}) : []
      tmp_posts = Post.where(:_id => {'$in' => item_ids})

      tmp_topics.each {|t| topics[t.id.to_s] = t}
      tmp_posts.each do |p|
        if p.root_id != p.id
          personal_responses[p.root_id.to_s] ||= []
          personal_responses[p.root_id.to_s] << p
        else
          posts[p.id.to_s] = p
        end
      end

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

        root_post.personal_responses = personal_responses[root_post.root.id.to_s] ? personal_responses[root_post.root.id.to_s].reverse : []
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

    def activity_feed(feed_id, display_types, page)
      if display_types.include?('Talk')
        display_types << 'Topic'
      end

      items = FeedContributeItem.where(:feed_id => feed_id, :root_type => {'$in' => display_types}).order_by(:last_response_time, :desc)
      items = items.skip((page-1)*20).limit(20)

      build_activity_feed(items)
    end

    def like_feed(feed_id, display_types, page)

      if display_types.include?('Talk')
        display_types << 'Topic'
      end

      items = FeedLikeItem.where(:feed_id => feed_id, :root_type => {'$in' => display_types}).order_by(:last_response_time, :desc)
      items = items.skip((page-1)*20).limit(20)

      build_like_feed(items)
    end

    def topic_feed(feed_ids, user_id, display_types, sort, page)
      items = FeedTopicItem.where(:root_type => {'$in' => display_types}, :mentions => {'$in' => feed_ids})

      if sort == 'newest'
        items = items.order_by(:last_response_time, :desc)
      else
        items = items.order_by(:p, :desc)
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

      personal_responses = {}
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

        root_post.personal_responses = personal_responses[root_post.root.id.to_s] ? personal_responses[root_post.root.id.to_s] : []
        root_post.public_talking = root_post.root.response_count

        # get the public responses
        root_post.public_responses = []
        unless i.root_type == 'Talk' || root_post.public_talking == 0
          root_post.public_responses = Post.public_responses(root_post.root.id, 1, 2)
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

        root_post.activity_responses = activity_responses[root_post.root.id.to_s] ? activity_responses[root_post.root.id.to_s] : []

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

  # Set some denormilized user data
  def denormalize_user
    self.build_user_snippet(
            :public_id => user.public_id,
            :username => user.username,
            :status => user.status,
            :first_name => user.first_name,
            :last_name => user.last_name,
            :fbuid => user.fbuid,
            :twuid => user.twuid,
            :use_fb_image => user.use_fb_image
    )
    self.user_snippet.id = user.id
  end

  def current_user_own
    grant_owner(user.id)
  end

end