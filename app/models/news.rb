class News < CoreObject

  field :title, :type => String
  slug :title

  validates :title, :length => { :minimum => 5, :maximum => 100 }
  validates :content, :length => { :minimum => 5, :maximum => 400 }

  attr_accessible :title
end
