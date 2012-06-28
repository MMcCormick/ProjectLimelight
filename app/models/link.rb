class Link < PostMedia

  validate :has_valid_url
  validates :title, :presence => true

end