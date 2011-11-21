class Settings
  include Mongoid::Document

  field :shares_email, default => true
  field :notify_email, default => true
  field :weekly_email, default => true

  embedded_in :user

  attr_accessible :shares_email, :notify_email, :weekly_email
end