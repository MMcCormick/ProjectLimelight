class Notification
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  include Mongoid::CachedJson

  include ModelUtilitiesHelper

  field :active, :default => true
  field :message
  field :type
  field :update_count, :default => 1 # how many times has this notification been used (comment comment comment) from the same user on the same object would create 1 notification that is updated
  field :notify, :default => false
  field :read, :default => false
  field :emailed, :default => false
  field :pushed, :default => false
  field :comment_id

  belongs_to :triggered_by, :class_name => 'User'
  belongs_to :object, :class_name => 'Post'
  belongs_to :object_user, :class_name => 'User'
  belongs_to :user

  index({ :user_id => 1, :type => 1 })

  def created_at
    id.generation_time
  end

  def notification_text
    case type.to_sym
      when :follow
        'is following you'
      when :mention
        "mentioned you in a post"
      when :repost
        "liked \"#{object.short_name}\""
      when :comment
        "commented on \"#{object.short_name}\""
      when :also # also signifies that someone has also responded to something your responded to
        "also commented on #{object_user.username}'s post \"#{object.short_name}\""
      else
        "did something weird... this is a mistake and the Limelight team has been notified to fix it!"
    end
  end

  json_fields \
    :id => { :definition => :_id, :properties => :short, :versions => [ :v1 ] },
    :read => { :properties => :short, :versions => [ :v1 ] },
    :user_id => { :properties => :short, :versions => [ :v1 ] },
    :message => { :properties => :short, :versions => [ :v1 ] },
    :type => { :properties => :short, :versions => [ :v1 ] },
    :sentence => { :definition => :notification_text, :properties => :short, :versions => [ :v1 ] },
    :created_at => { :definition => lambda { |instance| instance.created_at.to_i }, :properties => :short, :versions => [ :v1 ] },
    :created_at_pretty => { :definition => lambda { |instance| instance.pretty_time(instance.created_at) }, :properties => :short, :versions => [ :v1 ] },
    :created_at_short => { :definition => lambda { |instance| instance.short_time(instance.created_at) }, :properties => :short, :versions => [ :v1 ] },
    :triggered_by => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :object => { :type => :reference, :properties => :short, :versions => [ :v1 ] },
    :object_user => { :type => :reference, :properties => :short, :versions => [ :v1 ] }

  class << self

    # Creates and optionally sends a notification for a user
    # target_user = the user object we are adding the notification for
    # type = the type of notification (string)
    # notify = bool wether to send the notification or not via email and/or push message
    # triggered_by_user = the user object that triggered this notification, if there is one
    # message = optional message
    # object = optional object this notification is attached to
    # object_user = optional user associated with the object the notification is about
    # comment = optional comment this notification is attached to
    def add(target_user, type, notify, triggered_by_user=nil, message=nil, object=nil, object_user=nil, comment=nil)
      return if !target_user || (triggered_by_user && target_user.id == triggered_by_user.id)

      # Get a previous notification if there is one
      notification = Notification.where(:user_id => target_user.id, :type => type)
      if triggered_by_user
        notification = notification.where('triggered_by._id' => triggered_by_user.id)
      end
      if object
        notification = notification.where('object._id' => object.id)
      end
      notification = notification.first

      new_notification = false
      if notification
        new_notification = true if notification.read == true
        notification.update_count += 1
        notification.read = false
        notification.emailed = false
        notification.pushed = false
      else
        new_notification = true
        notification = Notification.new(
                :type => type,
                :message => message
        )
        notification.user = target_user
        notification.triggered_by = triggered_by_user if triggered_by_user
        notification.object = object if object
        notification.object_user = object_user if object_user
        notification.comment_id = comment.id if comment
        notification.notify = notify
      end

      if notification.save
        if new_notification
          target_user.unread_notification_count = target_user.unread_notification_count.to_i + 1

          if notification.notify && target_user.notify_immediately?(type)
            #if target_user.device_token  # pushing notification
            #  if Notification.send_push_notification(target_user.device_token, target_user.device_type, "#{triggered_by_user.fullname} #{notification.notification_text(1)}")
            #    target_user.last_notified = Time.now
            #    notification.pushed = true
            #    notification.save
            #  end
            #else # emailing notification
            Resque.enqueue_in(5.minutes, SendUserNotification, notification.id.to_s)
            #end
          end

          target_user.save
        end

        notification
      end
    end

    def remove(target_user, type, triggered_by_user=nil, object=nil, comment=nil)
      # find the notification
      notification = Notification.where(:user_id => target_user.id)
      if object
        notification = notification.where('object_id' => object.id)
        if comment
          notification = notification.where('comment_id' => comment.id)
        end
      end
      if triggered_by_user
        notification = notification.where("triggered_by_id" => triggered_by_user._id)
      end
      notification = notification.where(:type => type).first

      if notification
        unless notification.read
          target_user.unread_notification_count = target_user.unread_notification_count.to_i - 1
        end
        notification.destroy
      end
    end

  end

end