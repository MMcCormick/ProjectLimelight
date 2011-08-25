require 'factory_girl'

Factory.define :user do |u|
  u.name 'Test User'
  u.email 'user@test.com'
  u.password 'please'
end

Factory.define :news do |news|
  news.title "Foo Title"
  news.content "Foo Content"
  news.association :user
end