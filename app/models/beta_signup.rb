class BetaSignup
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :email
  field :invite_code_id
  field :emailed_invite, :default => false

  attr_accessible :email

  validates_uniqueness_of :email, :message => "That email is already taken"
  validates_presence_of :email, :message => "You must supply an email"
  validates_format_of :email, :message => 'That email is invalid',
            :with => /^(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})$/i
end