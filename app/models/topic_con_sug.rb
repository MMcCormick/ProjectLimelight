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
  field :inline
  field :reverse_name, :default => nil
  field :pull_from, :default => false, :type => Boolean
  field :reverse_pull_from, :default => false, :type => Boolean

  belongs_to :user

  validates_presence_of :topic1_id, :topic2_id, :topic1_name, :topic2_name, :topic1_slug, :topic2_slug, :con_id, :name, :user_id
  validate :unique_suggestion

  attr_protected :votes_count, :user_id

  def unique_suggestion
    if TopicConSug.exists?(conditions: { topic1_id: topic1_id, topic2_id: topic2_id, con_id: con_id, pull_from: pull_from, reverse_pull_from: reverse_pull_from })
      errors.add("", "That suggestion has already been made")
    end
  end
end