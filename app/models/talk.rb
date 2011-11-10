class Talk < CoreObject

  field :comments_count, :default => 0

  #TODO: fix the problem with tags increasing content length, then decrease this max
  validates :content, :length => { :minimum => 3, :maximum => 400 }

  has_many :comments

  def name
    content_clean
  end
end