class Talk < CoreObject

  validates :content, :length => { :minimum => 3, :maximum => 200 }

end
