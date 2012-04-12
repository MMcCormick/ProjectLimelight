class User
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Mongoid::Slug
  include Limelight::Images

  cache

  @marc_id = "4eb9cda1cddc7f4068000042"
  @matt_id = "4ebf1748cddc7f0c9f000002"
  class << self; attr_accessor :marc_id, :matt_id end

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  ## Database authenticatable
  field :email,              :type => String, :null => false
  field :encrypted_password, :type => String, :null => false

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

  # Denormilized:
  # Post.user_snippet.username
  # Post.user_mentions.username
  # Notification.object_user.username
  # Notification.triggered_by.username
  # Comment.user_snippet.username
  field :username
  slug :username

  # Denormilized:
  # Post.user_snippet.first_name
  # Post.user_mentions.first_name
  # Notification.object_user.first_name
  # Notification.triggered_by.first_name
  # Comment.user_snippet.first_name
  field :first_name

  # Denormilized:
  # Post.user_snippet.last_name
  # Post.user_mentions.last_name
  # Notification.object_user.last_name
  # Notification.triggered_by.last_name
  # Comment.user_snippet.last_name
  field :last_name

  field :status, :default => 'active'
  field :email
  field :gender
  field :birthday, :type => Date
  field :username_reset, :default => false
  field :time_zone, :type => String, :default => "Eastern Time (US & Canada)"
  field :roles, :default => []
  field :following_users_count, :type => Integer, :default => 0
  field :following_users, :default => []
  field :following_topics_count, :type => Integer, :default => 0
  field :following_topics, :default => []
  field :followers_count, :type => Integer, :default => 0
  field :likes_count, :type => Integer, :default => 0
  field :unread_notification_count, :type => Integer, :default => 0
  field :vote_pos_count, :default => 0
  field :vote_neg_count, :default => 0
  field :vote_ratio, :type => Float, :default => 0
  field :clout, :default => 1
  field :bio
  field :invite_code_id
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

  auto_increment :public_id

  embeds_many :social_connects

  has_many :posts
  has_many :links
  has_many :videos
  has_many :talks
  has_many :pictures
  has_many :topics
  has_many :topic_connections
  has_many :comments
  has_many :popularity_actions
  has_many :topic_con_sugs

  attr_accessor :login
  attr_accessible :username, :first_name, :last_name, :email, :password, :password_confirmation, :remember_me, :login, :bio, :invite_code_id

  validates :username, :uniqueness => { :case_sensitive => false, :message => 'Username is already taken' },
            :length => { :minimum => 3, :maximum => 15, :message => 'Username must be between 3 and 15 characters' },
            :format => { :with => /\A[a-zA-Z_0-9]+\z/, :message => "Username can only contain letters, numbers, and underscores" },
            :format => { :with => /^[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*$/, :message => "Username must start with a letter and end with a letter or number" }
  validates :email, :uniqueness => { :case_sensitive => false, :message => 'This email has already been used' }
  validates :bio, :length => { :maximum => 150, :message => 'Bio has a max length of 150' }
  validate :username_change
  validate :validate_invite_code, :on => :create

  after_create :neo4j_create, :add_to_soulmate, :follow_limelight_topic, :save_profile_image, :invite_stuff
  after_update :update_denorms#, :expire_caches
  before_destroy :remove_from_soulmate

  index [[ :slug, Mongo::ASCENDING ]]
  index [[ :public_id, Mongo::DESCENDING ]]
  index [[ :score, Mongo::DESCENDING ]]
  index :email
  index :following_topics
  index :following_users
  index "social_connects"

  # Return the users slug instead of their ID
  def to_param
    self.slug.downcase
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
    @remote_image_url = if facebook
                          self.use_fb_image = true
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
    invite = InviteCode.find(invite_code_id)
    unless invite && invite.usable?
      errors.add :invite_code_id, "Please enter a valid invite code"
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
      when 'UserSnippet'
        is_following_user?(target.id)
      when 'Topic'
        is_following_topic?(target.id)
      when 'TopicSnippet'
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
      Resque.enqueue(PushUnfollowUser, id.to_s, user.id.to_s)
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
      Resque.enqueue(PushUnfollowTopic, id.to_s, topic.id.to_s)
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

  def name
    username
  end

  def first_or_username
    if first_name then first_name else username end
  end

  def fullname
    if first_name and last_name then "#{first_name} #{last_name}" else nil end
  end

  def add_to_soulmate
    Resque.enqueue(SmCreateUser, id.to_s)
  end

  def remove_from_soulmate
    Resque.enqueue(SmDestroyUser, id.to_s)
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver
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
            'public_id' => public_id,
            'created_at' => created_at.to_i
    )
    Neo4j.neo.add_node_to_index('users', 'uuid', id.to_s, node)
  end

  def neo4j_update
    node = Neo4j.neo.get_node_index('users', 'uuid', id.to_s)
    Neo4j.neo.set_node_properties(node, {'username' => username, 'slug' => slug}) if node
  end

  def invite_stuff
    InviteCode.create(:user_id => id, :allotted => 3)
    invite = InviteCode.find(invite_code_id)
    invite.redeem
  end

  def influence_increases
    increases = []
    actions = PopularityAction.where("pop_snippets._id" => id, "pop_snippets.ot" => 'Topic').order_by(:et, :desc).limit(3).to_a
    actions.each do |action|
      action.pop_snippets.each do |snip|
        if snip.ot == "Topic" && snip.a > 0
          inc = InfluenceIncrease.new()
          inc.amount = snip.a
          inc.topic_id = snip.id
          inc.object_type = action.pop_snippets[0].ot
          inc.action = action.t
          increases << inc
        end
      end
    end

    topics = {}
    tmp_topics = Topic.where(:_id.in => increases.map{|i| i.topic_id})
    tmp_topics.each {|t| topics[t.id.to_s] = t}

    increases.each do |increase|
      increase.topic = topics[increase.topic_id.to_s]
    end
    increases.last(3)
  end

  def update_social_denorms
    user_snippet_updates = { "user_snippet.fbuid" => self.fbuid }
    user_mention_updates = { "user_mentions.$.fbuid" => self.fbuid }
    object_user_updates = { "object_user.fbuid" => self.fbuid }
    triggered_by_updates = { "triggered_by.$.fbuid" => self.fbuid }
    user_snippet_updates["user_snippet.twuid"] = self.twuid
    user_mention_updates["user_mentions.$.twuid"] = self.twuid
    object_user_updates["object_user.twuid"] = self.twuid
    triggered_by_updates["triggered_by.$.twuid"] = self.twuid

    Post.where(:user_id => id).update_all(user_snippet_updates)
    Post.where("user_mentions._id" => id).update_all(user_mention_updates)
    Post.where("likes._id" => id).update_all(user_mention_updates)
    Comment.where(:user_id => id).update_all(user_snippet_updates)
    Notification.where("object_user._id" => id).update_all(object_user_updates)
    Notification.where("triggered_by._id" => id).update_all(triggered_by_updates)
  end

  def auto_follow (provider)
    if provider == "facebook" && self.auto_follow_fb
      fb = self.facebook
      if fb
        friends = fb.get_connections("me", "friends")
        friends_uids = friends.map{|friend| friend['id']}
        registeredFriends = User.where("social_connects.uid" => {"$in" => friends_uids}, 'social_connects.provider' => 'facebook')
        registeredFriends.each do |friend|
          friend.follow_user(self) if friend.auto_follow_fb
          self.follow_user(friend) if self.auto_follow_fb
        end
        self.save
      end
    elsif provider == "twitter" && self.auto_follow_tw
      tw = self.twitter
      if tw
        follower_ids = tw.follower_ids.collection
        registeredFollowers = User.where("social_connects.uid" => {"$in" => follower_ids}, 'social_connects.provider' => 'twitter')
        registeredFollowers.each do |follower|
          follower.follow_user(self)
        end
        self.save

        following_ids = tw.friend_ids.collection.map{|id| id.to_s}
        registeredFollowing = User.where("social_connects.uid" => {"$in" => following_ids}, 'social_connects.provider' => 'twitter')
        registeredFollowing.each do |following|
          self.follow_user(following)
        end
        self.save
      end
    end
  end

  ##########
  # JSON
  ##########

  def as_json(options={})
    data = {
            :id => id.to_s,
            :type => 'User',
            :public_id => public_id,
            :slug => username.downcase,
            :username => username,
            :first_name => first_name,
            :last_name => last_name,
            :score => score,
            :following_users_count => following_users_count,
            :following_topics_count => following_topics_count,
            :followers_count => followers_count,
            :unread_notification_count => unread_notification_count,
            :images => User.json_images(self)
    }

    if options[:show_extra]
      data.merge!(
              :following_users => following_users,
              :following_topics => following_topics,
              :tutorial_step => tutorial_step,
              :tutorial1_step => tutorial1_step,
              :username_reset => username_reset,
              :facebook_id => fbuid,
              :twitter_id => twuid,
              :roles => roles
      )

      code = InviteCode.where(:user_id => id).first
      data[:invite_code] = code ? {:code => code.code, :remaining => code.remaining} : {}
    end

    data
  end

  class << self

    def json_images(model)
      {
        :original => model.image_url(nil, nil, 'current', true),
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
    def find_by_omniauth(omniauth, signed_in_resource=nil, invite_code=nil)
      new_user = false
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
          user.use_fb_image = true if user.image_versions == 0
          user.update_social_denorms
        end
        # Update the token
        connect.token = omniauth['credentials']['token']

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
                :username => username, :invite_code_id => invite.id,
                :first_name => extra["first_name"], :last_name => extra["last_name"],
                :gender => gender, :email => info["email"], :password => Devise.friendly_token[0,20]
        )
        user.username_reset = true
        user.birthday = Chronic.parse(extra["birthday"]) if extra["birthday"]
        connect = SocialConnect.new(:uid => omniauth["uid"], :provider => omniauth['provider'], :token => omniauth['credentials']['token'])
        connect.secret = omniauth['credentials']['secret'] if omniauth['credentials'].has_key?('secret')
        user.social_connects << connect
        user.use_fb_image = true if user.image_versions == 0
        user.update_social_denorms
      end

      if user && !user.confirmed?
        user.confirm!
        user.send_welcome_email
      end

      user.slug = user.id.to_s if new_user # set a temporary slug
      user.save :validate => false if user

      if user && new_connect
        Resque.enqueue(AutoFollow, user.id.to_s, connect.provider.to_s)
        #user.auto_follow(connect.provider.to_s)
      end

      user
    end
  end

  def daily_notification_types
    types = []
    types << "follow" if email_follow == "1"
    types << "mention" if email_mention == "1"
    types = types + ["also", "reply"] if email_comment == "1"
    types
  end

  protected

  class << self
    def find_for_database_authentication(conditions)
      login = conditions.delete(:login)
      self.any_of({ :slug => login.downcase.strip }, { :email => login.downcase.strip }).first
    end
  end

  def update_denorms
    user_snippet_updates = {}
    object_user_updates = {}
    triggered_by_updates = {}
    user_mention_updates = {}
    if username_changed?
      user_snippet_updates["user_snippet.username"] = self.username
      user_mention_updates["user_mentions.$.username"] = self.username
      object_user_updates["object_user.username"] = self.username
      triggered_by_updates["triggered_by.$.username"] = self.username
    end
    if first_name_changed?
      user_snippet_updates["user_snippet.first_name"] = self.first_name
      user_mention_updates["user_mentions.$.first_name"] = self.first_name
      object_user_updates["object_user.first_name"] = self.first_name
      triggered_by_updates["triggered_by.$.first_name"] = self.first_name
    end
    if last_name_changed?
      user_snippet_updates["user_snippet.last_name"] = self.last_name
      user_mention_updates["user_mentions.$.last_name"] = self.last_name
      object_user_updates["object_user.last_name"] = self.last_name
      triggered_by_updates["triggered_by.$.last_name"] = self.last_name
    end
    if use_fb_image_changed?
      user_snippet_updates["user_snippet.use_fb_image"] = self.use_fb_image
      user_mention_updates["user_mentions.$.use_fb_image"] = self.use_fb_image
      object_user_updates["object_user.use_fb_image"] = self.use_fb_image
      triggered_by_updates["triggered_by.$.use_fb_image"] = self.use_fb_image
    end
    unless user_snippet_updates.empty?
      Post.where(:user_id => id).update_all(user_snippet_updates)
      Post.where("user_mentions._id" => id).update_all(user_mention_updates)
      Post.where("likes._id" => id).update_all(user_mention_updates)
      Comment.where(:user_id => id).update_all(user_snippet_updates)
      Notification.where("object_user._id" => id).update_all(object_user_updates)
      Notification.where("triggered_by._id" => id).update_all(triggered_by_updates)
      neo4j_update
      Resque.enqueue(SmCreateUser, id.to_s)
    end
  end

end