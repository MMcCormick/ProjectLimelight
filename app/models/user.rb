class User
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Mongoid::Slug
  include Limelight::Images
  include Limelight::Popularity

  @marc_id = "4eb9cda1cddc7f4068000042"
  @matt_id = "4ebf1748cddc7f0c9f000002"
  class << self; attr_accessor :marc_id, :matt_id end

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  # Denormilized:
  # CoreObject.user_snippet.username
  # CoreObject.user_mentions.username
  # Notification.object_user.username
  # Notification.triggered_by.username
  # Comment.user_snippet.username
  field :username

  # Denormilized:
  # CoreObject.user_snippet.first_name
  # CoreObject.user_mentions.first_name
  # Notification.object_user.first_name
  # Notification.triggered_by.first_name
  # Comment.user_snippet.first_name
  field :first_name

  # Denormilized:
  # CoreObject.user_snippet.last_name
  # CoreObject.user_mentions.last_name
  # Notification.object_user.last_name
  # Notification.triggered_by.last_name
  # Comment.user_snippet.last_name
  field :last_name

  slug :username

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
  field :favorites, :default => []
  field :favorites_count, :type => Integer, :default => 0
  field :reposts_count, :type => Integer, :default => 0
  field :unread_notification_count, :default => 0
  field :vote_pos_count, :default => 0
  field :vote_neg_count, :default => 0
  field :vote_ratio, :type => Float, :default => 0
  field :clout, :default => 1
  field :bio
  field :invite_code_id

  field :shares_email, :default => true
  field :notify_email, :default => true
  field :weekly_email, :default => true

  auto_increment :public_id

  embeds_many :social_connects

  has_many :core_objects
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

  validates :username, :uniqueness => { :case_sensitive => false },
            :length => { :minimum => 3, :maximum => 15, :message => 'must be between 3 and 15 characters.' },
            :format => { :with => /\A[a-zA-Z_0-9]+\z/, :message => "can only contain letters, numbers, and underscores." },
            :format => { :with => /^[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*$/, :message => "must start with a letter and end with a letter or number." }
  validates :email, :uniqueness => { :case_sensitive => false }
  validates :bio, :length => { :maximum => 150 }
  validate :username_change
  validates_each :invite_code_id, :on => :create do |record, attr, value|
    invite = InviteCode.find(value)
    record.errors.add attr, "Please enter correct invite code" unless invite && invite.usable?
  end

  after_create :neo4j_create, :add_to_soulmate, :follow_limelight_topic, :save_profile_image, :send_welcome_email, :invite_stuff
  after_update :update_denorms, :expire_caches
  before_destroy :remove_from_soulmate

  index :slug
  index :email
  index "social_connects.uid"
  index :following_users
  index :ph
  index :pd
  index :pw
  index :pm
  index :pt

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
    hash = Digest::MD5.hexdigest(self.email.downcase)+'.jpeg'
    facebook = get_social_connect 'facebook'
    google = get_social_connect 'google_oath2'
    image_url = if facebook
                  "http://graph.facebook.com/#{facebook.uid}/picture?type=large"
                elsif google
                  google.image
                else
                  "http://www.gravatar.com/avatar/#{hash}?s=500&d=identicon"
                end

    write_out = open("/tmp/#{hash}", "wb")
    write_out.write(open(image_url).read)
    write_out.close

    image = self.images.create(:user_id => id)
    version = AssetImage.new(:isOriginal => true)
    version.id = image.id
    version.image.store!("/tmp/#{hash}")
    image.versions << version
    version.save
    self.save
  end

  def recalculate_vote_ratio
    self.vote_ratio = vote_neg_count > 0 ? vote_pos_count/vote_neg_count : vote_pos_count
  end

  def username_change
    if username_was && username_changed? && username_was != username
      if username_reset == false && !role?('admin')
        errors.add(:username, "cannot be changed right now")
      else
        self.username_reset = false
      end
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
      Resque.enqueue(SmUserFollowUser, id.to_s, user.id.to_s)
      Neo4j.follow_create(id.to_s, user.id.to_s, 'users', 'users')
      ActionFollow.create(:action => 'create', :from_id => id, :to_id => user.id, :to_type => 'User')
      user.add_pop_action(:flw, :a, self)
      user.save

      true
    end
  end

  def unfollow_user(user)
    if self.following_users.include?(user.id)
      self.following_users.delete(user.id)
      self.following_users_count -= 1
      user.followers_count -= 1
      Resque.enqueue(SmUserFollowUser, id.to_s, user.id.to_s)
      Resque.enqueue(Neo4jFollowDestroy, id.to_s, user.id.to_s)
      ActionFollow.create(:action => 'delete', :from_id => id, :to_id => user.id, :to_type => 'User')
      user.add_pop_action(:flw, :r, self)
      user.save

      true
    else
      false
    end
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
      Neo4j.follow_create(id.to_s, topic.id.to_s, 'users', 'topics')
      ActionFollow.create(:action => 'create', :from_id => id, :to_id => topic.id, :to_type => 'Topic')
      topic.add_pop_action(:flw, :a, self)
      topic.save

      true
    end
  end

  def unfollow_topic(topic)
    if self.following_topics.include?(topic.id)
      self.following_topics.delete(topic.id)
      self.following_topics_count -= 1
      topic.followers_count -= 1
      Resque.enqueue(Neo4jFollowDestroy, id.to_s, topic.id.to_s)
      ActionFollow.create(:action => 'delete', :from_id => id, :to_id => topic.id, :to_type => 'Topic')
      topic.add_pop_action(:flw, :r, self)
      topic.save

      true
    else
      false
    end
  end

  ###
  # FAVORITING
  ###

  def has_favorite?(object_id)
    favorites.include? object_id
  end

  def add_to_favorites(object)
    unless has_favorite? object.id
      self.favorites << object.id
      self.favorites_count += 1

      ActionFavorite.create(:action => 'create', :from_id => id, :to_id => object.id, :to_type => object.class.name)
    end
  end

  def remove_from_favorites(object)
    if has_favorite? object.id
      self.favorites.delete(object.id)
      self.favorites_count -= 1

      ActionFavorite.create(:action => 'destroy', :from_id => id, :to_id => object.id, :to_type => object.class.name)
    end
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

  def facebook
    #TODO
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
    node = Neo4j.neo.create_node('uuid' => id.to_s, 'type' => 'user', 'username' => username, 'slug' => slug, 'public_id' => public_id)
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

  class << self
    # Omniauth providers
    def find_by_omniauth(omniauth, signed_in_resource=nil, invite_code=nil)
      new_user = false
      no_code = false
      info = omniauth['info']
      extra = omniauth['extra']['raw_info']

      if signed_in_resource
        user = signed_in_resource
      else
        user = User.where("social_connects.uid" => omniauth['uid'], 'social_connects.provider' => omniauth['provider']).first
      end

      # Try to get via email if user not found and email provided
      unless user || !info['email']
        user = User.where(:email => info['email']).first
      end

      # If we found the user, update their token
      if user
        connect = user.social_connects.detect{|connection| connection.uid == omniauth['uid'] && connection.provider == omniauth['provider']}
        # Is this a new connection?
        unless connect
          connect = SocialConnect.new(:uid => omniauth["uid"], :provider => omniauth['provider'], :image => info['image'])
          connect.secret = omniauth['credentials']['secret'] if omniauth['credentials'].has_key?('secret')
          user.social_connects << connect
        end
        # Update the token
        connect.token = omniauth['credentials']['token']

      # If an invite code is in the session, create a new user with a stub password.
      elsif invite = InviteCode.first(conditions: {code: invite_code})
        if invite.usable?
          new_user = true
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
                  username: username, invite_code_id: invite.id,
                  first_name: extra["first_name"], last_name: extra["last_name"],
                  gender: gender, email: info["email"], password: Devise.friendly_token[0,20]
          )
          user.username_reset = true
          user.birthday = Chronic.parse(extra["birthday"]) if extra["birthday"]
          connect = SocialConnect.new(:uid => omniauth["uid"], :provider => omniauth['provider'], :token => omniauth['credentials']['token'])
          connect.secret = omniauth['credentials']['secret'] if omniauth['credentials'].has_key?('secret')
          user.social_connects << connect
        else
          no_code = true
        end

      # If no user found + error code provided
      else
        no_code = true
      end

      user.save :validate => false unless no_code

      if new_user == true
        user.slug = user.id.to_s # set a temporary slug
        user.save :validate => false
      end
      user
    end
  end

  def expire_caches
    User.expire_caches(id.to_s)
  end

  protected

  class << self
    def find_for_database_authentication(conditions)
      login = conditions.delete(:login)
      self.any_of({ :slug => login.downcase.strip }, { :email => login.downcase.strip }).first
    end

    def expire_caches(target_id)
      ActionController::Base.new.expire_cell_state UserCell, :sidebar, target_id
      ActionController::Base.new.expire_cell_state UserCell, :sidebar, "#{target_id}-mine"
      ActionController::Base.new.expire_cell_state UserCell, :sidebar, "#{target_id}-following"
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
    unless user_snippet_updates.empty?
      CoreObject.where(:user_id => id).update_all(user_snippet_updates)
      CoreObject.where("user_mentions._id" => id).update_all(user_mention_updates)
      CoreObject.where("likes._id" => id).update_all(user_mention_updates)
      Comment.where(:user_id => id).update_all(user_snippet_updates)
      Notification.where("object_user._id" => id).update_all(object_user_updates)
      Notification.where("triggered_by._id" => id).update_all(triggered_by_updates)
      neo4j_update
      expire_caches
      Resque.enqueue(SmCreateUser, id)
    end
  end

end