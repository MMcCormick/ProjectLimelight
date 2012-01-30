require "limelight"

class Comment
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Voting
  #include Limelight::Mentions
  include Limelight::Popularity

  field :content
  field :status, :default => "active"
  field :parent_id
  field :talk_id
  field :user_id
  field :depth, :default => 0
  field :path, :default => ""
  field :votes_count, :default => 0

  belongs_to :talk
  belongs_to :user

  embeds_one :user_snippet, as: :user_assignable

  validates :talk_id, :presence => true
  validates :content, :length => { :minimum => 3, :maximum => 150 }
  validates :depth, :numericality => { :less_than_or_equal_to => 5 }

  before_validation :set_path
  before_create :set_user_snippet, :current_user_own
  after_create :add_to_count, :action_log_create

  attr_accessible :content, :parent_id, :talk_id

  index(
    [
      [ :talk_id, Mongo::ASCENDING ],
      [ :path, Mongo::ASCENDING ],
      [ :created_at, Mongo::DESCENDING ]
    ]
  )

  def user_delete
    self.status = "deleted"
    action_log_delete
  end

  def send_notifications(current_user)
    parent = nil
    if depth == 0
      Notification.add(talk.user, :reply, true, current_user, nil, nil, true, talk, talk.user, nil)
    else
      parent = Comment.find(parent_id)
      Notification.add(parent.user, :reply, true, current_user, nil, nil, true, talk, talk.user, parent)
    end

    if depth == 0
      siblings = Comment.where(:talk_id => talk_id)
    else
      siblings = Comment.where(:parent_id => parent_id)
    end

    siblings.each do |sibling|
      unless (depth == 0 && talk.user_id == sibling.user_id) || (parent && parent.user_id == sibling.user_id)
        Notification.add(sibling.user, :also, true, current_user, nil, nil, true, talk, talk.user, parent)
      end
    end
  end

  class << self
    # Based on Newsmonger: https://github.com/banker/newsmonger
    # Return an array of comments, threaded, from highest to lowest votes.
    # Sorts by votes descending by default, but could use any other field.
    # If you want to build out an internal balanced score, pass that field in,
    # and be sure to index it on the database.
    def threaded_with_field(talk_id, field_name='created_at', limit)
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

      comments = assemble(results, map)

      results = {:show => [], :hide => []}
      if limit
        comments.each_with_index do |comment,i|
          if i < limit
            results[:show] << comment
          else
            results[:hide] << comment
          end
        end
      else
        results[:show] = comments
      end

      results
    end

    # Used by Comment#threaded_with_field to assemble the results.
    def assemble(results, map)
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
    talk.response_count += 1
    talk.save

    #if (talk.response_to)
    #  CoreObject.collection.update(
    #    {:_id => talk.response_to.id},
    #    {
    #      "$inc" => { :response_count => 1 }
    #    }
    #  )
    #end
  end

  def action_log_create
    ActionComment.create(:action => 'create', :from_id => user_snippet.id, :to_id => talk_id, :comment_id => id)
  end

  def action_log_delete
    ActionComment.create(:action => 'delete', :from_id => user_snippet.id, :to_id => talk_id, :comment_id => id)
  end

  def current_user_own
    grant_owner(user.id)
  end
end