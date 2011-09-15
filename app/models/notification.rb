require "limelight"

class Notification
  include Mongoid::Document
  include Mongoid::Paranoia
  include Limelight::Acl

  field :message
  field :status, :default => 'Active'
  field :user_id
  field :core_object_id

  embeds_one :sender_snippet, as: :user_assignable, :class_name => 'UserSnippet'
  embeds_many :receiver_snippets, :class_name => 'NotificationReceiverSnippet'
  embeds_one :shared_object_snippet, as: :core_object_assignable, :class_name => 'CoreObjectSnippet'

  attr_accessible :message

  validates_presence_of :receiver_snippets

  def set_sender_snippet(user)
    self.build_sender_snippet({id: user.id, username: user.username, first_name: user.first_name, last_name: user.last_name})
  end

  # TODO: this must always be called last because we are saving the receiver's unread notification count and must check if the notification is valid. Fix.
  def set_receiver_snippets(users)
    users.each do |user|
      found = false
      self.receiver_snippets.each do |receiver|
        found = true if receiver.id == user.id
      end
      if !found
        self.receiver_snippets.create({id: user.id, username: user.username, first_name: user.first_name, last_name: user.last_name})
        #something.save
        #self.receiver_snippets << something
        if self.valid?
          user.unread_notification_count += 1
          user.save
        end
      end
    end
  end

  def set_shared_object_snippet(object)
    self.build_shared_object_snippet({id: object.id, name: object.name, type: object._type})
  end
end