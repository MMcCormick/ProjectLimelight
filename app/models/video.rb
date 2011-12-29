class Video < CoreObject

  validate :has_valid_url
  validates :title, :presence => true
  field :embed_html

  def name
    title_clean
  end
end
