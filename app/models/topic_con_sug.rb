class TopicConSug
  include Mongoid::Document
  include Limelight::Voting

  field :topic1_id
  field :topic1_name
  field :topic1_slug
  field :topic2_id
  field :topic2_name
  field :topic2_slug
  field :user_id
  field :con_id
  field :name
  field :reverse_name, :default => nil
  field :pull_from, :default => false, :type => Boolean
  field :reverse_pull_from, :default => false, :type => Boolean

  belongs_to :user

  validates_presence_of :topic1_id, :topic2_id, :topic1_name, :topic2_name, :topic1_slug, :topic2_slug, :con_id, :name, :user_id

  attr_protected :votes_count, :user_id

end