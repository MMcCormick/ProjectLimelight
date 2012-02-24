class Video < Post
  include Limelight::Images

  validate :has_valid_url
  validates :title, :presence => true

  def name
    title_clean
  end
end