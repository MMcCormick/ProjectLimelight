class Asset

  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :user_id

  belongs_to :user

end