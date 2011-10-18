require 'spec_helper'

describe "Follows" do
  include LoginHelper
  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }

  describe "creating follows", :js=>true do
    before(:each) do
      sign_in_as user1
    end

    it "should create a follow when a user clicks another's follow button" do
      visit user_path user2
      find(".followB").click
      user = User.find(user1.id)
      user.following_users.should include user2.id
    end

    it "should create a follow when a user clicks a topic's follow button" do
      topic = FactoryGirl.create(:topic)
      visit topic_path topic
      find(".followB").click
      user = User.find(user1.id)
      user.following_topics.should include topic.id
    end
  end

  describe "feeds" do
    before(:each) do
      login_as user1
    end

    it "should display a followed user's posts in the follower's feed" do
      xhr :post, create_follow_path, :id => user2.id, :type => "User"
      FactoryGirl.create(:talk, :user => user2, :content_raw => "testy!")
      visit user_feed_path user1
      page.should have_content "testy!"
    end

    it "should display content mentioning a followed topic in the follower's feed" do
      topic = FactoryGirl.create(:topic)
      FactoryGirl.create(:talk, :user => user2, :content_raw => "i tagged #[#{topic.id}##{topic.name}]")
      xhr :post, create_follow_path, :id => topic.id, :type => "Topic"
      visit user_feed_path user1
      page.should have_content "i tagged #{topic.name}"
    end
  end
end