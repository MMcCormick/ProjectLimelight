class User
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Denormilized:
  # CoreObject.user_snippet.username
  # Topic.user_snippet.username
  field :username, :type => String

  # Denormilized:
  # CoreObject.user_snippet.first_name
  # Topic.user_snippet.first_name
  field :first_name, :type => String

  # Denormilized:
  # CoreObject.user_snippet.last_name
  # Topic.user_snippet.last_name
  field :last_name, :type => String

  slug :username

  has_many :core_objects
  has_many :news
  has_many :talks
  has_many :topics

  validates :username, :presence => true
  validates :username, :email, :uniqueness => { :case_sensitive => false }
  attr_accessible :username, :first_name, :last_name, :email, :password, :password_confirmation, :remember_me
end