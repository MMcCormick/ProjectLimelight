class User
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps::Updated
  include Mongoid::CachedJson
  include Limelight::Images
  include ModelUtilitiesHelper

  @marc_id = "4eb9cda1cddc7f4068000042"
  @matt_id = "4ebf1748cddc7f0c9f000002"
  @limelight_user_id = "4f971b6ccddc7f1480000046"
  class << self; attr_accessor :marc_id, :matt_id, :limelight_user_id end

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  ## Database authenticatable
  field :encrypted_password, :type => String

  ## Trackable
  field :sign_in_count,      :type => Integer
  field :current_sign_in_at, :type => Time
  field :last_sign_in_at,    :type => Time
  field :current_sign_in_ip, :type => String
  field :last_sign_in_ip,    :type => String

  # Token authenticatable
  field :authentication_token, :type => String

  ## Confirmable
  field :confirmation_token,   :type => String
  field :confirmed_at,         :type => Time
  field :confirmation_sent_at, :type => Time
  #field :unconfirmed_email,    :type => String # Only if using reconfirmable

  ## Rememberable
  field :remember_created_at, :type => Time

  field :username
  field :slug
  field :first_name
  field :last_name
  field :status, :default => 'active'
  field :email
  field :gender
  field :birthday, :type => Date
  field :username_reset, :default => false
  field :email_reset, :default => false
  field :time_zone, :type => String, :default => "Eastern Time (US & Canada)"
  field :roles, :default => []
  field :following_users_count, :type => Integer, :default => 0
  field :following_users, :default => []
  field :following_topics_count, :type => Integer, :default => 0
  field :following_topics, :default => []
  field :followers_count, :type => Integer, :default => 0
  field :posts_count, :default => 0
  field :likes_count, :type => Integer, :default => 0
  field :unread_notification_count, :type => Integer, :default => 0
  field :clout, :default => 1
  field :bio
  field :tutorial_step, :default => 1, :type => Integer
  field :tutorial1_step, :default => 1, :type => Integer # user feed tutorial
  # Email settings: 2 = immediate email, 1 = daily digest, 0 = off
  field :email_follow, :default => "2"
  field :email_comment, :default => "2"
  field :email_mention, :default => "2"
  field :weekly_email, :default => true
  field :score, :default => 0.0
  field :use_fb_image, :default => false
  field :auto_follow_fb, :default => true
  field :auto_follow_tw, :default => true
  field :og_follows, :default => true # whether to push follows to open graph
  field :og_likes, :default => true # ^ for likes
  field :used_invite_code_id
  field :unlimited_code_id
  field :origin # what did the user use to originally signup (limelight, facebook, etc)
  field :neo4j_id
  field :topic_activity, :default => {} # keeps track of how many posts a user has in topics (just counts)
  field :topic_likes, :default => {} # keeps track of how many likes a user has in topics (just counts)

  embeds_many :social_connects

  has_many :posts
  has_many :post_media, :class_name => 'PostMedia'
  has_many :topics
  has_many :topic_connections
  has_many :comments
  has_many :popularity_actions
  has_many :topic_con_sugs
  has_one  :invite_code

  attr_accessor :login
  attr_accessible :username, :first_name, :last_name, :email, :password, :password_confirmation, :remember_me, :login, :bio, :used_invite_code_id

  with_options :if => :is_active? do |user|
    user.validates :username, :uniqueness => { :case_sensitive => false, :message => 'Username is already taken' },
              :length => { :minimum => 3, :maximum => 15, :message => 'Username must be between 3 and 15 characters' },
              :format => { :with => /\A[a-zA-Z_0-9]+\z/, :message => "Username can only contain letters, numbers, and underscores" },
              :format => { :with => /^[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*$/, :message => "Username must start with a letter and end with a letter or number" }
    user.validates :email, :uniqueness => { :case_sensitive => false, :message => 'This email has already been used' }
    user.validates :bio, :length => { :maximum => 150, :message => 'Bio has a max length of 150' }
    user.validate :validate_invite_code, :on => :create
    user.validate :username_change
  end

  before_create :generate_slug
  after_create :neo4j_create, :add_to_soulmate, :follow_limelight_topic, :save_profile_image, :invite_stuff, :send_personal_email
  before_update :update_slug
  after_update :update_denorms
  before_destroy :remove_from_soulmate

  index({ :slug => 1 })
  index({ :email => 1 })
  index({ :following_topics => 1 })
  index({ :following_users => 1 })
  index({ :following_users => 1 })
  index({ "social_connects" => 1 })

  # Return the users slug instead of their ID
  def to_param
    username
  end

  def created_at
    id.generation_time
  end

  def generate_slug
    self.slug = username.parameterize
  end

  def update_slug
    if username_changed?
      generate_slug
    end
  end

  def is_active?
    status == 'active'
  end

  # Overrides devise methods
  # Checks whether a password is needed or not. For validations only.
  # Passwords are always required if it's a new record, or if the password
  # or confirmation are being set somewhere.
  def password_required?
    status == 'active' && (!persisted? || !password.nil? || !password_confirmation.nil?)
  end
  def email_required?
    status == 'active'
  end

  # override username. if the user is a twitter user only, return their twitter username, else their limelight username
  def username
    if status == 'twitter'
      twitter = get_social_connect 'twitter'
      twitter.username
    else
      @attributes['username']
    end
  end

  def follow_limelight_topic
    limelight = Topic.find(Topic.limelight_id)
    if limelight
      self.follow_topic(limelight)
      self.save
      limelight.save
    end
  end

  # Pull image from Gravatar
  def save_profile_image
    facebook = get_social_connect 'facebook'
    if facebook
      self.use_fb_image = true
      save
    end
  end

  def recalculate_vote_ratio
    self.vote_ratio = vote_neg_count > 0 ? vote_pos_count/vote_neg_count : vote_pos_count
  end

  def username_change
    if username_was && username_changed? && username_was != username
      if username_reset == false && !role?('admin')
        errors.add(:username, "Username cannot be changed right now")
      else
        self.username_reset = false
      end
    end
  end

  def validate_invite_code
    used_invite = used_invite_code_id ? InviteCode.find(used_invite_code_id) : nil
    unless used_invite && used_invite.usable?
      errors.add :used_invite_code_id, "Please enter a valid invite code"
    end
  end

  ###
  # ROLES
  ###

  # Checks to see if this user has a given role
  def role?(role)
    self.roles.include? role
  end

  # Adds a role to this user
  def grant_role(role)
    self.roles << role unless self.roles.include?(role)
  end

  # Removes a role from this user
  def revoke_role(role)
    if self.roles
      self.roles.delete(role)
    end
  end

  ###
  # FOLLOWING
  ###

  def follow_object(target)
    case target.class.name
      when 'User'
        follow_user(target)
      when 'Topic'
        follow_topic(target)
    end
  end

  def unfollow_object(target)
    case target.class.name
      when 'User'
        unfollow_user(target)
      when 'Topic'
        unfollow_topic(target)
    end
  end

  def is_following?(target)
    case target.class.name
      when 'User'
        is_following_user?(target.id)
      when 'Topic'
        is_following_topic?(target.id)
    end
  end

  def is_following_user?(user_id)
    self.following_users.include? user_id
  end

  def follow_user(user)
    if (self.following_users.include?(user.id)) || (id == user.id)
      false
    else
      self.following_users << user.id
      self.following_users_count += 1
      user.followers_count += 1
      Resque.enqueue(Neo4jFollowCreate, id.to_s, user.id.to_s, 'users', 'users')
      Resque.enqueue(SmUserFollowUser, id.to_s, user.id.to_s)
      Resque.enqueue(PushFollowUser, id.to_s, user.id.to_s)
      ActionFollow.create(:action => 'create', :from_id => id, :to_id => user.id, :to_type => 'User')
      user.save

      true
    end
  end

  def push_follow_user(user)
    FeedUserItem.follow(self, user)
  end


  def unfollow_user(user)
    if self.following_users.include?(user.id)
      self.following_users.delete(user.id)
      self.following_users_count -= 1
      user.followers_count -= 1
      Resque.enqueue(Neo4jFollowDestroy, id.to_s, user.id.to_s, 'users', 'users')
      Resque.enqueue(SmUserUnfollowUser, id.to_s, user.id.to_s)
      #Resque.enqueue(PushUnfollowUser, id.to_s, user.id.to_s)
      ActionFollow.create(:action => 'delete', :from_id => id, :to_id => user.id, :to_type => 'User')

      user.save

      true
    else
      false
    end
  end

  def push_unfollow_user(user)
    FeedUserItem.unfollow(self, user)
  end

  def is_following_topic?(topic_id)
    self.following_topics.include? topic_id
  end

  def follow_topic(topic)
    if self.following_topics.include?(topic.id)
      false
    else
      self.following_topics << topic.id
      self.following_topics_count += 1
      topic.followers_count += 1
      Resque.enqueue(Neo4jFollowCreate, id.to_s, topic.id.to_s, 'users', 'topics')
      Resque.enqueue(PushFollowTopic, id.to_s, topic.id.to_s)
      ActionFollow.create(:action => 'create', :from_id => id, :to_id => topic.id, :to_type => 'Topic')
      topic.save

      true
    end
  end

  def push_follow_topic(topic)
    FeedUserItem.follow(self, topic)
  end

  def unfollow_topic(topic)
    if self.following_topics.include?(topic.id)
      self.following_topics.delete(topic.id)
      self.following_topics_count -= 1
      topic.followers_count -= 1
      Resque.enqueue(Neo4jFollowDestroy, id.to_s, topic.id.to_s, 'users', 'topics')
      #Resque.enqueue(PushUnfollowTopic, id.to_s, topic.id.to_s)
      ActionFollow.create(:action => 'delete', :from_id => id, :to_id => topic.id, :to_type => 'Topic')
      topic.save

      true
    else
      false
    end
  end

  def push_unfollow_topic(topic)
    FeedUserItem.unfollow(self, topic)
  end

  def topic_activity_add(topic_id)
    self.topic_activity[topic_id.to_s] ||= 0
    self.topic_activity[topic_id.to_s] += 1
    self.topic_activity = Hash[topic_activity.sort_by{|id,count| count}.reverse]
  end

  def topic_activity_subtract(topic_id)
    if topic_activity[topic_id.to_s]
      self.topic_activity[topic_id.to_s] -= 1
      self.topic_activity = Hash[topic_activity.sort_by{|id,count| count}.reverse]
    end
  end

  def topic_activity_recalculate
    self.topic_activity = {}
    self.posts_count = 0
    posts.each do |p|
      p.topic_mention_ids.each do |t|
        topic_activity_add(t)
      end
      self.posts_count += 1
    end
  end

  def topics_by_activity
    topics = Topic.where(:_id => {"$in" => topic_activity.map{|k,v| k}})
    results = []
    topic_activity.each do |id,count|
      topic = topics.find(id)
      if topic
        results << {
                :count => count,
                :topic => topic
        }
      end
    end
    results
  end

  def topic_likes_add(topic_id)
    self.topic_likes[topic_id.to_s] ||= 0
    self.topic_likes[topic_id.to_s] += 1
    self.topic_likes = Hash[topic_likes.sort_by{|id,count| count}.reverse]
  end

  def topic_likes_subtract(topic_id)
    if topic_likes[topic_id.to_s]
      self.topic_likes[topic_id.to_s] -= 1
      self.topic_likes = Hash[topic_likes.sort_by{|id,count| count}.reverse]
    end
  end

  def topic_likes_recalculate
    self.topic_likes = {}
    self.likes_count = 0
    likes = Post.where(:like_ids => id)
    likes.each do |p|
      p.topic_mention_ids.each do |t|
        topic_likes_add(t)
      end
      self.likes_count += 1
    end
  end

  def topics_by_likes
    topics = Topic.where(:_id => {"$in" => topic_likes.map{|k,v| k}})
    results = []
    topic_likes.each do |id,count|
      topic = topics.find(id)
      if topic
        results << {
                :count => count,
                :topic => topic
        }
      end
    end
    results
  end

  def name
    username
  end

  def first_or_username
    if first_name then first_name else username end
  end

  def fullname
    if first_name and last_name then "#{first_name} #{last_name}" else username end
  end

  def add_to_soulmate
    Resque.enqueue(SmCreateUser, id.to_s)
  end

  def remove_from_soulmate
    Resque.enqueue(SmDestroyUser, id.to_s)
  end

  def send_welcome_email
    UserMailer.welcome_email(self.id.to_s).deliver
    UserMailer.welcome_email_admins(self.id.to_s).deliver
  end

  def send_personal_email
    hour = Time.now.hour
    variation = rand(7200)
    if hour < 11
      delay = Chronic.parse('Today at 11AM').to_i - Time.now.utc.to_i + variation
      Resque.enqueue_in(delay, SendPersonalWelcome, id.to_s, "today")
    elsif hour >= 11 && hour < 18
      Resque.enqueue_in(1.hours + variation, SendPersonalWelcome, id.to_s, "today")
    else
      delay = Chronic.parse('Tomorrow at 11AM').to_i - Time.now.utc.to_i + variation
      Resque.enqueue_in(delay, SendPersonalWelcome, id.to_s, "today")
    end
  end

  def get_social_connect provider
    social_connects.each do |social|
      return social if social.provider == provider
    end
    nil
  end

  def fbuid
    facebook = get_social_connect('facebook')
    if facebook
      facebook.uid
    end
  end

  def twuid
    twitter = get_social_connect('twitter')
    if twitter
      twitter.uid
    end
  end

  def facebook
    connection = social_connects.detect{|connection| connection.provider == 'facebook'}
    if connection
      @fb_user ||= Koala::Facebook::API.new(connection.token)
    else
      nil
    end
  end

  def twitter
    provider = get_social_connect('twitter')
    if provider
      Twitter.configure do |config|
        config.consumer_key = ENV['TWITTER_KEY']
        config.consumer_secret = ENV['TWITTER_SECRET']
        config.oauth_token = provider.token
        config.oauth_token_secret = provider.secret
      end
      @twitter ||= Twitter.new
    else
      nil
    end
  end

  def neo4j_create
    node = Neo4j.neo.create_node(
            'uuid' => id.to_s,
            'type' => 'user',
            'username' => username,
            'created_at' => created_at.to_i,
            'score' => score.to_i
    )
    Neo4j.neo.add_node_to_index('users', 'uuid', id.to_s, node)
    self.neo4j_id = node['self'].split('/').last
    save
    node
  end

  def neo4j_update
    node = Neo4j.neo.get_node_index('users', 'uuid', id.to_s)
    Neo4j.neo.set_node_properties(node, {'username' => username, 'score' => score.to_i}) if node
  end

  def invite_stuff
    unless invite_code
      self.create_invite_code(:allotted => 3)
    end

    if used_invite_code_id
      used_invite = InviteCode.find(used_invite_code_id)
      used_invite.redeem if used_invite
    end
  end

  def get_unlimited_code
    if unlimited_code_id
      unlimited = InviteCode.find(unlimited_code_id)
    else
      unlimited = InviteCode.new(:allotted => 0)
      self.unlimited_code_id = unlimited.id
      save
    end
    unlimited
  end

  def influence_increases(limit, full=false)
    increases = []
    actions = PopularityAction.where("pop_snippets._id" => id, "pop_snippets.ot" => 'Topic').desc(:et).limit(limit)

    actions.each do |action|
      action.pop_snippets.each do |snip|
        if snip.ot == "Topic" && snip.a > 0
          inc = InfluenceIncrease.new()
          inc.amount = snip.a
          inc.topic_id = snip.id
          inc.post_id = action.oid
          inc.object_type = action.pop_snippets[0].ot
          inc.action = action.t
          inc.triggered_by_id = action.user_id
          inc.created_at_pretty = pretty_time(Time.at(action.et))
          increases << inc
        end
      end
    end

    topics = {}
    tmp_topics = Topic.where(:_id.in => increases.map{|i| i.topic_id})
    tmp_topics.each {|t| topics[t.id.to_s] = t}

    if full
      posts = {}
      post_ids = increases.map{|i| i.post_id}
      tmp_posts = Post.where(:_id.in => post_ids).to_a
      tmp_posts.each {|t| posts[t.id.to_s] = t}

      triggered = {}
      tmp_triggered = User.where(:_id.in => increases.map{|i| i.triggered_by_id})
      tmp_triggered.each {|t| triggered[t.id.to_s] = t}
    end

    increases.each do |increase|
      increase.topic = topics[increase.topic_id.to_s]
      if full
        increase.post = posts[increase.post_id.to_s]
        increase.triggered_by = triggered[increase.triggered_by_id.to_s]
      end
    end
    increases.first(limit)
  end

  def update_social_denorms
    #object_user_updates = { "object_user.fbuid" => self.fbuid }
    #triggered_by_updates = { "triggered_by.$.fbuid" => self.fbuid }
    #object_user_updates["object_user.twuid"] = self.twuid
    #triggered_by_updates["triggered_by.$.twuid"] = self.twuid
    #
    #Notification.where("object_user._id" => id).update_all(object_user_updates)
    #Notification.where("triggered_by._id" => id).update_all(triggered_by_updates)
  end

  def auto_follow (provider)
    puts 'starting auto follow'
    if provider == "facebook" && self.auto_follow_fb
      fb = facebook
      if fb
        friends = fb.get_connections("me", "friends")
        friends_uids = friends.map{|friend| friend['id']}
        registeredFriends = User.where("social_connects.uid" => {"$in" => friends_uids}, 'social_connects.provider' => 'facebook')
        registeredFriends.each do |friend|
          if friend.auto_follow_fb
            friend.follow_user(self)
            friend.save
          end
          if self.auto_follow_fb
            if follow_user(friend)
              notification = Notification.add(friend, :follow, true, self)
              Pusher["#{friend.id.to_s}_private"].trigger('new_notification', notification.to_json) if notification
            end
          end
        end
        save :validate => false
      end
    elsif provider == "twitter"
      tw = twitter
      if tw
        follower_ids = tw.follower_ids.collection.map{|id| id.to_s}
        registeredFollowers = User.where("social_connects.uid" => {"$in" => follower_ids}, 'social_connects.provider' => 'twitter').to_a
        registeredFollowers.each do |follower|
          follower.follow_user(self) if follower.auto_follow_tw
          follower.save
        end

        if self.auto_follow_tw
          following_ids = tw.friend_ids.collection.map{|id| id.to_s}
          registeredFollowing = User.where("social_connects.uid" => {"$in" => following_ids}, 'social_connects.provider' => 'twitter')
          registeredFollowing.each do |following|
            if follow_user(following)
              notification = Notification.add(following, :follow, true, self)
              Pusher["#{following.id.to_s}_private"].trigger('new_notification', notification.to_json) if notification
            end
          end
        end
        save :validate => false
      end
    end
  end

  ##########
  # JSON
  ##########

  def mixpanel_data(extra=nil)
    {
            :distinct_id => id.to_s,
            "User#{extra if extra} Username" => username,
            "User#{extra if extra} Birthday" => birthday,
            "User#{extra if extra} Score" => score,
            "User#{extra if extra} Clout" => clout,
            "User#{extra if extra} Following Users" => following_users_count,
            "User#{extra if extra} Following Topics" => following_topics_count,
            "User#{extra if extra} Followers" => followers_count,
            "User#{extra if extra} Connected Twitter?" => twuid ? true : false,
            "User#{extra if extra} Connected Facebook?" => fbuid ? true : false,
            "User#{extra if extra} Auto Follow Twitter?" => auto_follow_tw,
            "User#{extra if extra} Auto Follow Facebook?" => auto_follow_fb,
            "User#{extra if extra} Origin" => origin,
            "User#{extra if extra} Status" => status,
            "User#{extra if extra} Sign Ins" => sign_in_count,
            "User#{extra if extra} Last Sign In" => current_sign_in_at,
            "User#{extra if extra} Created At" => created_at,
            "User#{extra if extra} Confirmed At" => confirmed_at
    }
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :type => { :definition => lambda { |instance| 'User' }, :properties => :short, :versions => [ :v1 ] },
    :slug => { :properties => :short, :versions => [ :v1 ] },
    :username => { :properties => :short, :versions => [ :v1 ] },
    :name => { :definition => :fullname, :properties => :short, :versions => [ :v1 ] },
    :first_name => { :properties => :short, :versions => [ :v1 ] },
    :last_name => { :properties => :short, :versions => [ :v1 ] },
    :score => { :properties => :short, :versions => [ :v1 ] },
    :following_users_count => { :properties => :short, :versions => [ :v1 ] },
    :following_topics_count => { :properties => :short, :versions => [ :v1 ] },
    :followers_count => { :properties => :short, :versions => [ :v1 ] },
    :posts_count => { :properties => :short, :versions => [ :v1 ] },
    :likes_count => { :properties => :short, :versions => [ :v1 ] },
    :unread_notification_count => { :properties => :short, :versions => [ :v1 ] },
    :images => { :definition => lambda { |instance| User.json_images(instance) }, :properties => :short, :versions => [ :v1 ] },
    :status => { :properties => :short, :versions => [ :v1 ] },
    :url => { :definition => lambda { |instance| "/users/#{instance.to_param}" }, :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => lambda { |instance| instance.created_at.to_i }, :properties => :short, :versions => [ :v1 ] },
    :created_at_pretty => { :definition => lambda { |instance| instance.pretty_time(instance.created_at) }, :properties => :short, :versions => [ :v1 ] },
    :created_at_short => { :definition => lambda { |instance| instance.short_time(instance.created_at) }, :properties => :short, :versions => [ :v1 ] },
    :facebook_id => { :definition => :fbuid, :properties => :short, :versions => [ :v1 ] },
    :twitter_id => { :definition => :twuid, :properties => :short, :versions => [ :v1 ] },
    :roles => { :properties => :short, :versions => [ :v1 ] },
    :following_topics => { :properties => :public, :versions => [ :v1 ] },
    :following_users => { :properties => :public, :versions => [ :v1 ] },
    :tutorial_step => { :properties => :public, :versions => [ :v1 ] },
    :tutorial1_step => { :properties => :public, :versions => [ :v1 ] },
    :username_reset => { :properties => :public, :versions => [ :v1 ] },
    :invite_code => { :type => :reference, :properties => :public, :versions => [ :v1 ] }

  class << self

    def json_images(model)
      {
        :ratio => model.image_ratio,
        :original => model.image_url(nil, nil, nil, true),
        :fit => {
          :large => model.image_url(:fit, :large),
          :normal => model.image_url(:fit, :normal),
          :small => model.image_url(:fit, :small)
        },
        :square => {
          :small => model.image_url(:square, :small)
        }
      }
    end

  ##########
  # END JSON
  ##########

    # Omniauth providers
    def find_by_omniauth(omniauth, signed_in_resource=nil, invite_code=nil, request_env=nil)
      new_user = false
      login = false
      info = omniauth['info']
      extra = omniauth['extra']['raw_info']

      existing_user = User.where("social_connects.uid" => omniauth['uid'], 'social_connects.provider' => omniauth['provider']).first
      # Try to get via email if user not found and email provided
      unless existing_user || !info['email']
        existing_user = User.where(:email => info['email']).first
      end

      if signed_in_resource && existing_user && signed_in_resource != existing_user
        user = signed_in_resource
        user.errors[:base] << "There is already a user with that account"
        return user
      elsif signed_in_resource
        user = signed_in_resource
      elsif existing_user
        user = existing_user
      end

      invite = invite_code ? InviteCode.find(invite_code) : nil

      # If we found the user, update their token
      if user
        connect = user.social_connects.detect{|connection| connection.uid == omniauth['uid'] && connection.provider == omniauth['provider']}
        # Is this a new connection?
        unless connect
          new_connect = true
          connect = SocialConnect.new(:uid => omniauth["uid"], :provider => omniauth['provider'], :image => info['image'])
          connect.secret = omniauth['credentials']['secret'] if omniauth['credentials'].has_key?('secret')

          user.social_connects << connect
          user.use_fb_image = true if omniauth['provider'] == 'facebook' && user.images.length == 0
          user.update_social_denorms
        end
        # Update the token
        connect.token = omniauth['credentials']['token']

        unless signed_in_resource
          login = true
        end

      # If an invite code is in the session, create a new user with a stub password.
      elsif invite && invite.usable?
        new_user = true
        new_connect = true
        if extra["gender"] && !extra["gender"].blank?
          gender = extra["gender"] == 'male' || extra["gender"] == 'm' ? 'm' : 'f'
        else
          gender = nil
        end

        username = ""
        #username = info['nickname'].gsub(/[^a-zA-Z0-9]/, '')
        #existing_username = User.where(:slug => username).first
        #if existing_username
        #  username += Random.rand(99).to_s
        #end

        user = User.new(
                :username => username, :used_invite_code_id => invite.id,
                :first_name => extra["first_name"], :last_name => extra["last_name"],
                :gender => gender, :email => info["email"], :password => Devise.friendly_token[0,20]
        )
        user.username_reset = true
        user.birthday = Chronic.parse(extra["birthday"]) if extra["birthday"]
        connect = SocialConnect.new(:uid => omniauth["uid"], :provider => omniauth['provider'], :token => omniauth['credentials']['token'])
        connect.secret = omniauth['credentials']['secret'] if omniauth['credentials'].has_key?('secret')
        user.social_connects << connect
        user.origin = omniauth['provider']
        user.use_fb_image = true if user.images.length == 0
        user.update_social_denorms
      end

      if user && !user.confirmed?
        user.confirm!
        user.send_welcome_email
      end

      user.slug = user.id.to_s if new_user # set a temporary slug
      user.save :validate => false if user

      if user && new_connect
        Resque.enqueue(AutoFollow, user.id.to_s, connect.provider.to_s) unless user.username.blank?

        if connect.provider == 'facebook'
          Resque.enqueue(AutoFollowFBLikes, user.id.to_s)
        end
      end

      if new_user && request_env
        Resque.enqueue(MixpanelTrackEvent, "Signup", user.mixpanel_data, request_env.select{|k,v| v.is_a?(String) || v.is_a?(Numeric) })
      end

      if login == true && request_env
        Resque.enqueue(MixpanelTrackEvent, "Login", user.mixpanel_data.merge!("Login Method" => omniauth['provider']), request_env.select{|k,v| v.is_a?(String) || v.is_a?(Numeric) })
      end

      user
    end
  end

  def daily_notification_types
    types = []
    types << "follow" if email_follow == "1"
    types << "mention" if email_mention == "1"
    types = types + ["also", "comment"] if email_comment == "1"
    types
  end

  def notify_immediately?(notification_type)
    type = notification_type.to_s
    if %w(comment also).include?(type) && email_comment == "2"
      true
    elsif type == "follow" && email_comment == "2"
      true
    elsif type == "mention" && email_mention == "2"
      true
    else
      false
    end
  end

  protected

  class << self
    def find_for_database_authentication(conditions)
      login = conditions.delete(:login)
      self.any_of({ :slug => login.downcase.strip }, { :email => login.downcase.strip }).first
    end
  end

  def update_denorms
    update = false
    if username_changed?
      update = true
      if username_was.blank? && !social_connects.empty?
        Resque.enqueue(AutoFollow, self.id.to_s, social_connects.first.provider.to_s)
      end
    end
    if status_changed?
      update = true
    end
    if first_name_changed?
      update = true
    end
    if last_name_changed?
      update = true
    end
    if use_fb_image_changed?
      update = true
    end
    if update
      neo4j_update
      Resque.enqueue(SmCreateUser, id.to_s)
    end

    if score_changed?
      Resque.enqueue_in(10.minutes, ScoreUpdate, 'User', id.to_s)
    end
  end

end