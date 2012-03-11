class Video < Post

  validate :has_valid_url
  validates :title, :presence => true

  def name
    title_clean
  end
end