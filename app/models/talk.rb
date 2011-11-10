class Talk < CoreObject

  validates :content, :length => { :minimum => 3, :maximum => 200 }

  has_many :comments

  def name
    content_clean
  end
end