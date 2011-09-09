class News < CoreObject

  # Denormilized:
  # CoreObject.response_to.name
  # CoreObjectShare.core_object_snippet.name
  field :title

  slug :title

  validates :title, :length => { :minimum => 5, :maximum => 100 }
  validates :content, :length => { :minimum => 5, :maximum => 400 }

  attr_accessible :title

  def name
    self.title
  end
end
