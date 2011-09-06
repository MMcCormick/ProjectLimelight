class Video < CoreObject
  field :url, :type => String
  field :title, :type => String

  attr_accessible :url, :title

  slug :title

  validates :title, :length => { :minimum => 5, :maximum => 50 },
                    :presence => true
  validates :url, :presence => true
  validates_format_of :url, :with => URI::regexp(%w(http https))
end
