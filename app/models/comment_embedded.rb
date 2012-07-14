require "limelight"

class CommentEmbedded
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include Mongoid::CachedJson
  include Limelight::Acl
  #include Limelight::Throttle

  field :content
  field :status, :default => "active"

  belongs_to :user, :index => true

  embedded_in :post_media

  validates :content, :length => { :minimum => 3, :maximum => 500, :message => :length }

  before_create :current_user_own
  after_create :action_log_create

  attr_accessible :content

  def created_at
    id.generation_time
  end

  def send_notifications(user)
    notification = Notification.add(_parent.user, :comment, true, user, nil, _parent, _parent.user, nil)

    unless _parent.user_id == user_id
      Pusher["#{_parent.user.id.to_s}_private"].trigger('new_notification', notification.to_json)
    end

    siblings = _parent.comments
    used_ids = []
    siblings.each do |sibling|
      unless used_ids.include?(sibling.user_id) || (_parent.user_id == sibling.user_id) || (sibling.user_id == user.id)
        notification = Notification.add(sibling.user, :also, true, user, nil, _parent, _parent.user, sibling)
        unless sibling.user_id == user_id
          Pusher["#{sibling.user_id.to_s}_private"].trigger('new_notification', notification.to_json)
        end
      end
      used_ids << sibling.user_id
    end
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :content => { :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => lambda { |instance| instance.created_at.to_i }, :properties => :short, :versions => [ :v1 ] },
    :user => { :type => :reference, :properties => :short, :versions => [ :v1 ] }


  private

  def action_log_create
    ActionComment.create(:action => 'create', :from_id => user_id, :to_id => _parent.id, :comment_id => id)
  end

  def action_log_delete
    ActionComment.create(:action => 'delete', :from_id => user_id, :to_id => _parent.id, :comment_id => id)
  end

  def current_user_own
    grant_owner(user.id)
  end
end