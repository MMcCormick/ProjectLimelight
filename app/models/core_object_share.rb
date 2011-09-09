require "acl"

class CoreObjectShare
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl

  field :user_id
  field :core_object_id

  embeds_one :sender_snippet, as: :user_assignable, :class_name => 'UserSnippet'
  embeds_many :receiver_snippets, as: :user_assignable, :class_name => 'UserSnippet'
  embeds_one :shared_object_snippet, as: :core_object_assignable, :class_name => 'CoreObjectSnippet'

  belongs_to :user
  belongs_to :core_object
  validates_presence_of :user_id, :sender_snippet, :shared_object_snippet
  attr_accessible :core_object_id

  def set_sender_snippet(user)
    self.build_sender_snippet({id: user.id, username: user.username, first_name: user.first_name, last_name: user.last_name})
  end

  def set_receiver_snippets(users)
    users.each do |user|
      found = false
      self.receiver_snippets.each do |receiver|
        found = true if receiver.id == user.id
      end
      if !found
        self.receiver_snippets << UserSnippet.new({id: user.id, username: user.username, first_name: user.first_name, last_name: user.last_name})
      end
    end
  end

  def set_shared_object_snippet(object)
    self.build_shared_object_snippet({id: object.id, name: object.name, _type: object._type})
  end

end