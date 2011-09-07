class User
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Mongoid::Slug

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Denormilized:
  # CoreObject.user_snippet.username
  # CoreObject.user_mentions.username
  # Topic.user_snippet.username
  field :username

  # Denormilized:
  # CoreObject.user_snippet.first_name
  # CoreObject.user_mentions.first_name
  # Topic.user_snippet.first_name
  field :first_name

  # Denormilized:
  # CoreObject.user_snippet.last_name
  # CoreObject.user_mentions.first_name
  # Topic.user_snippet.last_name
  field :last_name

  slug :username

  field :roles, :default => []
  field :following_users_count, :default => 0
  field :following_users, :default => []
  field :following_topics_count, :default => 0
  field :following_topics, :default => []
  field :followers_count, :default => 0
  field :favorites_count, :default => 0
  field :reposts_count, :default => 0

  has_many :core_objects
  has_many :news
  has_many :videos
  has_many :talks
  has_many :pictures
  has_many :topics

  validates :username, :presence => true
  validates :username, :email, :uniqueness => { :case_sensitive => false }
  attr_accessible :username, :first_name, :last_name, :email, :password, :password_confirmation, :remember_me

  # Return the users slug instead of their ID
  def to_param
    self.slug
  end

  # Checks to see if this user has a given role
  def has_role?(role)
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

  def is_following_user?(user_id)
    self.following_users.include? user_id
  end

  def toggle_follow_user(user)
    if is_following_user? user.id
      unfollow_user user
    else
      follow_user user
    end
  end

  def follow_user(user)
    if !self.following_users.include?(user.id)
      self.following_users << user.id
      self.following_users_count += 1
      user.followers_count += 1
    end
  end

  def unfollow_user(user)
    if self.following_users.include?(user.id)
      self.following_users.delete(user.id)
      self.following_users_count -= 1
      user.followers_count -= 1
    end
  end

  def is_following_topic?(topic_id)
    self.following_topics.include? topic_id
  end

  def toggle_follow_topic(topic)
    if is_following_topic? topic.id
      unfollow_topic topic
    else
      follow_topic topic
    end
  end

  def follow_topic(topic)
    if !self.following_topics.include?(topic.id)
      self.following_topics << topic.id
      self.following_topics_count += 1
      topic.followers_count += 1
    end
  end

  def unfollow_topic(topic)
    if self.following_topics.include?(topic.id)
      self.following_topics.delete(topic.id)
      self.following_topics_count -= 1
      topic.followers_count -= 1
    end
  end
end