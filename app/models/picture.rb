class Picture < Post

  validates :title, :presence => true

  def name
    title_clean
  end

end