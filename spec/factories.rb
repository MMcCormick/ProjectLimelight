require 'factory_girl'

Factory.define :user do |u|
  u.username 'foouser'
  u.first_name 'First'
  u.last_name 'Last'
  u.email 'user@test.com'
  u.password 'please'
end

Factory.define :news do |news|
  news.title "Foo Title"
  news.content "Foo Content"
  news.association :user
end

Factory.define :talk do |talk|
  talk.content "Foo Content"
  talk.association :user
end