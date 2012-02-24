object @user
attributes :id, :username

node(:url) do |user|
  user_url user
end