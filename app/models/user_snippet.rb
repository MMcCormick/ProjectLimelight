# Embeddable user snippet that holds useful (denormalized) user info
class UserSnippet
  include Mongoid::Document
  include Limelight::Images

  field :username
  field :first_name
  field :last_name
  field :public_id

  embedded_in :user_assignable, polymorphic: true

  attr_accessible :username, :first_name, :last_name, :public_id, :_id

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
end