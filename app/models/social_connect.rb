class SocialConnect
  include Mongoid::Document

  field :provider
  field :uid, :type => String
  field :token
  field :secret
  field :username
  field :image
  field :source, :default => 'Limelight'
  field :fetch_shares, :default => false
  field :fetch_likes, :default => false

  embedded_in :user

end