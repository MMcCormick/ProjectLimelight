require "limelight"

class Comment
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include Mongoid::CachedJson
  include Limelight::Acl
  include Limelight::Throttle
  include ModelUtilitiesHelper

  field :content
  field :status, :default => "active"
  field :parent_id
  field :depth, :default => 0
  field :path, :default => ""
  field :talk_id

  belongs_to :post, index: true
  belongs_to :user, index: true

  validates :post, :presence => true
  validates :content, :length => { :minimum => 3, :maximum => 500, :message => :length }
  validates :depth, :numericality => { :less_than_or_equal_to => 5 }

  before_validation :set_path
  before_create :current_user_own
  after_create :add_to_count, :action_log_create

  attr_accessible :content

  def created_at
    id.generation_time
  end

  def user_delete
    self.status = "deleted"
    action_log_delete
  end

  def add_to_count
    post.comment_count += 1
    post.save
  end

  def send_notifications(user)
    notification = Notification.add(post.user, :comment, true, user, nil, post, post.user, nil)

    unless post.user.id == user.id
      Pusher["#{post.user.id.to_s}_private"].trigger('new_notification', notification.to_json)
    end

    siblings = Comment.where(:post_id => post.id)
    used_ids = []
    siblings.each do |sibling|
      unless used_ids.include?(sibling.user_id.to_s) || (post.user_id == sibling.user_id) || (sibling.user_id == user.id)
        notification = Notification.add(sibling.user, :also, true, user, nil, post, post.user, sibling)
        unless sibling.user.id == user.id
          Pusher["#{sibling.user_id.to_s}_private"].trigger('new_notification', notification.to_json)
        end
      end
      used_ids << sibling.user_id.to_s
    end
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :content => { :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => lambda { |instance| instance.created_at.to_i }, :properties => :short, :versions => [ :v1 ] },
    :user => { :type => :reference, :properties => :short, :versions => [ :v1 ] }


  class << self
    # Based on Newsmonger: https://github.com/banker/newsmonger
    # Return an array of comments, threaded, from highest to lowest votes.
    # Sorts by votes descending by default, but could use any other field.
    # If you want to build out an internal balanced score, pass that field in,
    # and be sure to index it on the database.
    def threaded_with_field(post_id)
      comments = Comment.where(:post_id => post_id).desc(:_id)
      #results, map = [], {}
      #comments.each do |comment|
      #  if comment.parent_id.blank?
      #    results << comment
      #  else
      #    comment.path =~ /:([\d|\w]+)$/
      #    if parent = $1
      #      map[parent] ||= []
      #      map[parent] << comment
      #    end
      #  end
      #end
      #
      #assemble(results, map)
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

    # get the threads for multiple posts in one query
    def multiple_threads(post_ids)
      comments = Comment.where(:post_id => {"$in" => post_ids}).desc(:created_at)
      threads = {}
      comments.each do |c|
        threads[c.post_id.to_s] ||= []
        threads[c.post_id.to_s] << c
      end
      threads
    end
  end

  private

  def set_path
    unless self.parent_id.blank?
      parent        = Comment.find(self.parent_id)
      self.post_id  = parent.post_id
      self.depth    = parent.depth + 1
      self.path     = parent.path + ":" + parent.id.to_s
    end
  end

  def action_log_create
    ActionComment.create(:action => 'create', :from_id => user_id, :to_id => post_id, :comment_id => id)
  end

  def action_log_delete
    ActionComment.create(:action => 'delete', :from_id => user_id, :to_id => post_id, :comment_id => id)
  end

  def current_user_own
    grant_owner(user.id)
  end
end