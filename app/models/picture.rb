class Picture < CoreObject
  include Limelight::Images

  validates :title, :presence => true

  def name
    title_clean
  end

end