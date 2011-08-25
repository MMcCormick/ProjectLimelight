class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  field :name

  has_many :core_objects
  has_many :news

  validates :name, :presence => true
  validates :name, :email, :uniqueness => { :case_sensitive => false }
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
end

