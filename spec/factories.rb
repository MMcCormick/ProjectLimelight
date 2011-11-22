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
    content_raw "Talk Content"
    association :user
  end

  factory :link do
    title "Link Title"
    content "Link Content"
    content_raw "Link Content"
    url "http://foobar.links"
    association :user
  end

  factory :picture do
    title "Picture Title"
    content "Picture Content"
    content_raw "Picture Content"
    url "http://picture.foo"
    association :user
  end

  factory :video do
    title "Video Title"
    content "Video Content"
    content_raw "Video Content"
    provider_name "Video Provider"
    provider_video_id "foobarid"
    url "http://video.foo"
    association :user
  end

  factory :comment do
    content "Comment Content"
    content_raw "Comment Content"
    depth 0
    association :user
    association :talk
  end

  factory :topic do
    sequence(:name) { |n| "topic#{n}" }
    association :user
  end

  factory :vote do
    amount 1
  end
end