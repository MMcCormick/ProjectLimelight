# Embeddable user snippet that holds useful (denormalized) user info
class UserSnippet
  include Mongoid::Document
  include Limelight::Images

  field :username
  field :first_name
  field :last_name
  field :status, :default => 'active'
  field :public_id
  field :fbuid
  field :twuid
  field :use_fb_image

  embedded_in :user_assignable, polymorphic: true

  attr_accessible :username, :status, :first_name, :last_name, :public_id, :_id, :fbuid, :twuid, :use_fb_image

  # Return the users username instead of their ID
  def to_param
    username.to_url
  end

  def first_or_username
    if first_name then first_name else username end
  end

  def fullname
    if first_name and last_name then "#{first_name} #{last_name}" else nil end
  end

  def as_json
    {
            :id => id.to_s,
            :type => 'User',
            :status => status,
            :public_id => public_id,
            :slug => username.downcase,
            :username => username,
            :first_name => first_name,
            :last_name => last_name,
            :images => User.json_images(self),
            :url => status == 'twitter' ? "http://twitter.com/#{username}" : "/users/#{to_param}"
    }
  end

end