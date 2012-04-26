class Picture < Post

  validates :title, :presence => true

  def name
    title
  end

end