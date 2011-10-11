class Talk < CoreObject

  validates :content, :length => { :minimum => 3, :maximum => 200 }

  def name
    content_clean
  end
end