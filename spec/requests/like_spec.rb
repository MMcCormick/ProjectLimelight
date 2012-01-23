require 'spec_helper'

describe "Likes" do
  include LoginHelper
  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }

  it "should create a like when a user clicks an object's like button", :js=>true do
    talk = FactoryGirl.create(:talk, :content_raw => "yay content")
    sign_in_as user1
    visit root_path
    find(".likeB").click
    talk = Talk.find(talk.id)
    talk.likes.should include user1.id
  end

  it "should display a followed user's likes in the follower's feed" do
    talk = FactoryGirl.create(:talk, :content_raw => "yay content")
    login_as user2
    xhr :post, create_like_path, :id => talk.id
    logout
    login_as user1
    xhr :post, create_follow_path, :id => user2.id, :type => "User"
    visit user_feed_path user1
    page.should have_content "yay content"
  end
end