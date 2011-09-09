class Video < CoreObject

  field :url, :type => String

  # Denormilized:
  # CoreObject.response_to.name
  # CoreObjectShare.core_object_snippet.name
  field :title, :type => String

  slug :title

  validates :title, :length => { :minimum => 5, :maximum => 50 },
                    :presence => true
  validates :url, :presence => true
  validates_format_of :url, :with => URI::regexp(%w(http https))

  attr_accessible :url, :title

  def name
    self.title
  end
end
