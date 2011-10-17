require 'spec_helper'

describe "Follows" do
  include LoginHelper
  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }

  it "should create a follow when a user clicks another's follow button", :js=>true do
    sign_in_as user1
    visit user_path user2
    find(".followB").click
    user = User.find(user1.id)
    user.following_users.should include user2.id      #wtf
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

    it "should display content about a followed topic in the follower's feed", :focus=>true do
      xhr :post, create_follow_path, :id => user2.id, :type => "User"
      FactoryGirl.create(:talk, :user => user2, :content_raw => "testy!")
      visit user_feed_path user1
      page.should have_content "testy!"
    end
  end
end