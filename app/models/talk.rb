class Talk < CoreObject

  field :comments_count, :default => 0

  validates :content, :length => { :minimum => 3, :maximum => 200 }

  has_many :comments

  def name
    content_clean
  end
end