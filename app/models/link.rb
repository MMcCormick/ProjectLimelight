class Link < Post

  validate :has_valid_url
  validates :title, :presence => true

  def name
    title
  end
end