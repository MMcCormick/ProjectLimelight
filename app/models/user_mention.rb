# Embeddable user snippet that holds useful (denormalized) user info
class UserMention
  include Mongoid::Document

  field :username
  field :first_name
  field :last_name
  field :public_id

  embedded_in :user_mentionable, polymorphic: true

  # Return the users username instead of their ID
  def to_param
    self.username.to_url
  end

  def as_json
    {
            :id => id.to_s,
            :type => 'User',
            :public_id => public_id,
            :slug => user.username.downcase,
            :username => username,
            :first_name => first_name,
            :last_name => last_name,
            :images => User.json_images(self),
            :url => "/users/#{to_param}"
    }
  end
end