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
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

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

  field :status, :default => 'Active'
  field :email
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

  field :shares_email, :default => true
  field :notify_email, :default => true
  field :weekly_email, :default => true

  auto_increment :public_id

  has_many :core_objects
  has_many :links
  has_many :videos
  has_many :talks
  has_many :pictures
  has_many :topics
  has_many :topic_connections
  has_many :comments
  has_many :popularity_actions

  attr_accessor :login
  attr_accessible :username, :first_name, :last_name, :email, :password, :password_confirmation, :remember_me, :login, :bio

  validates :username, :uniqueness => { :case_sensitive => false },
            :length => { :minimum => 3, :maximum => 15, :message => 'must be between 3 and 15 characters.' },
            :format => { :with => /\A[a-zA-Z_0-9]+\z/, :message => "can only contain letters, numbers, and underscores." },
            :format => { :with => /^[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*$/, :message => "must start with a letter and end with a letter or number." }
  validates :email, :uniqueness => { :case_sensitive => false }
  validates :bio, :length => { :maximum => 150 }

  after_create :add_to_soulmate, :follow_limelight_topic, :save_profile_image, :send_welcome_email
  after_update :update_denorms, :expire_caches
  before_destroy :remove_from_soulmate

  index :slug
  index :following_users
  index :ph
  index :pd
  index :pw
  index :pm
  index :pt

  # Return the users slug instead of their ID
  def to_param
    self.slug
  end

  def follow_limelight_topic
    limelight = Topic.find(Topic.limelight_id)
    if limelight
      self.follow_topic(limelight)
      self.save
    end
  end

  # Pull image from Gravatar
  def save_profile_image
    hash = Digest::MD5.hexdigest(self.email.downcase)+'.jpeg'
    image_url = "http://www.gravatar.com/avatar/#{hash}?s=500&d=monsterid"

    writeOut = open("/tmp/#{hash}", "wb")
    writeOut.write(open(image_url).read)
    writeOut.close

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
      Resque.enqueue(SmUserFollowUser, id.to_s, user.id.to_s)
      true
    end
  end

  def unfollow_user(user)
    if self.following_users.include?(user.id)
      self.following_users.delete(user.id)
      self.following_users_count -= 1
      user.followers_count -= 1
      Resque.enqueue(SmUserFollowUser, id.to_s, user.id.to_s)
      true
    else
      false
    end
  end

  def is_following_topic?(topic_id)
    self.following_topics.include? topic_id
  end

  def follow_topic(topic)
    if !self.following_topics.include?(topic.id)
      self.following_topics << topic.id
      self.following_topics_count += 1
      topic.followers_count += 1
      true
    else
      false
    end
  end

  def unfollow_topic(topic)
    if self.following_topics.include?(topic.id)
      self.following_topics.delete(topic.id)
      self.following_topics_count -= 1
      topic.followers_count -= 1
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
    end
  end

  def remove_from_favorites(object)
    if has_favorite? object.id
      self.favorites.delete(object.id)
      self.favorites_count -= 1
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

  protected

  def self.find_for_database_authentication(conditions)
    login = conditions.delete(:login)
    self.any_of({ :username => login }, { :email => login }).first
  end

  def update_denorms
    #TODO: update soulmate
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
    if !user_snippet_updates.empty?
      CoreObject.where(:user_id => id).update_all(user_snippet_updates)
      CoreObject.where("user_mentions._id" => id).update_all(user_mention_updates)
      Comment.where(:user_id => id).update_all(user_snippet_updates)
      Notification.where("object_user._id" => id).update_all(object_user_updates)
      Notification.where("triggered_by._id" => id).update_all(triggered_by_updates)
    end
  end

  def expire_caches
    ActionController::Base.new.expire_cell_state UserCell, :sidebar_left, id.to_s
    ActionController::Base.new.expire_cell_state UserCell, :sidebar_right, id.to_s
    ActionController::Base.new.expire_cell_state UserCell, :sidebar_right, "#{id.to_s}-following"
  end

end