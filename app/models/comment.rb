require "limelight"

class Comment
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Voting
  include Limelight::Mentions

  field :content
  field :parent_id
  field :talk_id
  field :user_id
  field :depth, :default => 0
  field :path, :default => ""
  field :votes_count, :default => 0

  belongs_to :talk
  belongs_to :user

  embeds_one :user_snippet, as: :user_assignable
  embeds_many :votes, as: :votable

  validates :talk_id, :presence => true
  validates :content, :length => { :minimum => 3, :maximum => 150 }
  validates :depth, :numericality => { :only_integer => true, :less_than_or_equal_to => 5 }

  before_validation :set_path
  before_create :set_user_snippet
  after_create :add_to_count

  attr_accessible :content, :parent_id, :talk_id

  # Based on Newsmonger: https://github.com/banker/newsmonger
  # Return an array of comments, threaded, from highest to lowest votes.
  # Sorts by votes descending by default, but could use any other field.
  # If you want to build out an internal balanced score, pass that field in,
  # and be sure to index it on the database.
  def self.threaded_with_field(talk_id, field_name='created_at')
    comments = Comment.where(:talk_id => talk_id).asc(:path).desc(field_name)
    results, map = [], {}
    comments.each do |comment|
      if comment.parent_id.blank?
        results << comment
      else
        comment.path =~ /:([\d|\w]+)$/
        if parent = $1
          map[parent] ||= []
          map[parent] << comment
        end
      end
    end
    assemble(results, map)
  end

  # Used by Comment#threaded_with_field to assemble the results.
  def self.assemble(results, map)
    list = []
    results.each do |result|
      if map[result.id.to_s]
        list << result
        list += assemble(map[result.id.to_s], map)
      else
        list << result
      end
    end
    list
  end

  private

  def set_user_snippet
    self.build_user_snippet({id: user.id, public_id: user.public_id, username: user.username, first_name: user.first_name, last_name: user.last_name})
  end

  def set_path
    unless self.parent_id.blank?
      parent        = Comment.find(self.parent_id)
      self.talk_id  = parent.talk_id
      self.depth    = parent.depth + 1
      self.path     = parent.path + ":" + parent.id.to_s
    end
  end

  def add_to_count
    talk.comments_count += 1
    talk.save
  end
end