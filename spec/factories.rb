FactoryGirl.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    first_name 'First'
    last_name 'Last'
    sequence(:email) { |n| "user#{n}@example.com" }
    password 'please'
  end

  factory :talk do
    content "Talk Content"
    association :user
  end

  factory :news do
    title "News Title"
    content "News Content"
    url "http://foobar.news"
    association :user
  end

  factory :picture do
    title "Picture Title"
    content "Picture Content"
    url "http://picture.foo"
    association :user
  end

  factory :video do
    title "Video Title"
    content "Video Content"
    provider_name "Video Provider"
    provider_video_id "foobarid"
    url "http://video.foo"
    association :user
  end
end