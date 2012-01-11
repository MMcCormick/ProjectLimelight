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

  before_update :acceptance

  def unique_suggestion
    if TopicConSug.exists?(conditions: { topic1_id: topic1_id, topic2_id: topic2_id, con_id: con_id, pull_from: pull_from,
                                         reverse_pull_from: reverse_pull_from, id: {"$ne" => id} })
      errors.add("", "That suggestion has already been made")
    end
    if Neo4j.get_connection(con_id, topic1_id, topic2_id)
      errors.add("", "That connection already exists")
    end
  end

  def admin_vote(amount)
    accept if amount > 0
    reject if amount < 0
  end

  def acceptance
    if votes_count_changed?
      if votes_count > 2
        accept
      elsif votes_count < -4
        reject
      end
    end
  end

  def accept
    con = TopicConnection.find(con_id)
      topic1 = Topic.find(topic1_id)
      topic2 = Topic.find(topic2_id)
      TopicConnection.add(con, topic1, topic2, user_id, {:pull => pull_from, :reverse_pull => reverse_pull_from})
  end

  def reject
    self.destroy()
  end
end