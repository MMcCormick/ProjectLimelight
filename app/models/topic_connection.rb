class TopicConnection
  include Mongoid::Document
  include Mongoid::Timestamps

  # Denormalized in Topic.topic_connection_snippet
  field :name
  field :user_id
  field :pull_from, :type => Boolean
  field :opposite

  belongs_to :user

  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :user_id, :presence => true

  attr_accessible :name, :pull_from, :opposite

  after_create :set_opposite

  # Return the topic slug instead of its ID
  def to_param
    self.name.to_url
  end

  protected

  def set_opposite
    if opposite == "one"
      self.opposite = id
      self.pull_from = false
    elsif !opposite.blank?
      opposite_connection = TopicConnection.find(opposite)
      if opposite_connection.opposite.blank?
        opposite_connection.opposite = id
        opposite_connection.save
      else
        self.opposite = ""
      end
    end
    save
  end
end