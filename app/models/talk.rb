class Talk < Post

  field :is_popular, :default => false
  field :first_talk, :default => false

  has_many :comments
  validates :content, :presence => true

  attr_accessible :first_talk

  def name
    content
  end
end