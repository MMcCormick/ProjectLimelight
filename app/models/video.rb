class Video < CoreObject
  include Limelight::Images

  field :embed_html

  validate :has_valid_url
  validates :title, :presence => true

  attr_accessible :embed_html

  def name
    title_clean
  end
end