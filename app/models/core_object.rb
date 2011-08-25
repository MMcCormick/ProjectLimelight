class CoreObject
  include Mongoid::Document

  field :title, :type => String
  field :content, :type => String
  field :user_id, :type => Integer

  belongs_to :user

  validates :user_id, :presence => true
end
