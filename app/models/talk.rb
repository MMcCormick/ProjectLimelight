class Talk < CoreObject

  slug :content

  validates :content, :length => { :minimum => 3, :maximum => 200 }
end
