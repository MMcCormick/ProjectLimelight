require "limelight"

class Comment
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include Limelight::Acl

  include ModelUtilitiesHelper

  field :content
  field :status, :default => "active"
  field :parent_id
  field :talk_id
  field :user_id
  field :depth, :default => 0
  field :path, :default => ""

  belongs_to :talk
  belongs_to :user

  embeds_one :user_snippet, as: :user_assignable

  validates :talk_id, :presence => true
  validates :content, :length => { :minimum => 3, :maximum => 200, :message => :length }
  validates :depth, :numericality => { :less_than_or_equal_to => 5 }

  before_validation :set_path
  before_create :set_user_snippet, :current_user_own
  after_create :add_to_count, :action_log_create

  attr_accessible :content, :talk_id

  index(
    [
      [ :talk_id, Mongo::DESCENDING ],
    ]
  )
  index [[ :parent_id, Mongo::DESCENDING ]]

  def created_at
    id.generation_time
  end

  def user_delete
    self.status = "deleted"
    action_log_delete
  end

  def add_to_count
    talk.response_count = talk.response_count.to_i + 1
    talk.update_response_counts(user_snippet.id)
    talk.save
  end

  def send_notifications(user)
    notification = Notification.add(talk.user, :comment, true, user, nil, talk, talk.user, nil)
    Pusher["#{talk.user.id.to_s}_private"].trigger('new_notification', notification.to_json)
    siblings = Comment.where(:talk_id => talk.id)
    used_ids = []
    siblings.each do |sibling|
      unless used_ids.include?(sibling.user_id.to_s) || (talk.user_id == sibling.user_id) || (sibling.user_id == user.id)
        notification = Notification.add(sibling.user, :also, true, user, nil, talk, talk.user, sibling)
        Pusher["#{sibling.user_id.to_s}_private"].trigger('new_notification', notification.to_json)
      end
      used_ids << sibling.user_id.to_s
    end
  end

  def as_json
    {
            :id => id.to_s,
            :content => content,
            :created_at => created_at,
            :created_at_pretty => pretty_time(created_at),
            :created_at_short => short_time(created_at),
            :user => user.as_json
    }
  end

  class << self
    # Based on Newsmonger: https://github.com/banker/newsmonger
    # Return an array of comments, threaded, from highest to lowest votes.
    # Sorts by votes descending by default, but could use any other field.
    # If you want to build out an internal balanced score, pass that field in,
    # and be sure to index it on the database.
    def threaded_with_field(talk_id)
      comments = Comment.where(:talk_id => talk_id).desc(:created_at)
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
      comments = Comment.where(:talk_id => {"$in" => post_ids}).desc(:created_at)
      threads = {}
      comments.each do |c|
        threads[c.talk_id.to_s] ||= []
        threads[c.talk_id.to_s] << c
      end
      threads
    end
  end

  private

  def set_user_snippet
    self.build_user_snippet({id: user.id, public_id: user.public_id, username: user.username, first_name: user.first_name,
                             last_name: user.last_name, fbuid: user.fbuid, twuid: user.twuid, use_fb_image: user.use_fb_image})
    self.user_snippet.id = user.id
  end

  def set_path
    unless self.parent_id.blank?
      parent        = Comment.find(self.parent_id)
      self.talk_id  = parent.talk_id
      self.depth    = parent.depth + 1
      self.path     = parent.path + ":" + parent.id.to_s
    end
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