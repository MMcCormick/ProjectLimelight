class News
  include Mongoid::Document

  field :title, :type => String
  field :content, :type => String
  field :user_id, :type => Integer

  belongs_to :user

  validates :content, :length => { :maximum => 400 }
end
