FactoryGirl.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    first_name 'First'
    last_name 'Last'
    sequence(:email) { |n| "user#{n}@example.com" }
    password 'please'
  end

  factory :talk do
    content "Foo Content"
    association :user
  end

  factory :news do
    title "Foo Title"
    content "Foo Content"
    association :user
  end
end