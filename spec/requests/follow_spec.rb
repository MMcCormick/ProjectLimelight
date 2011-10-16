require 'spec_helper'

describe "Follows", :js=>true, :focus=>true do
  include LoginHelper
  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }

  before(:each) do
    sign_in_as user1
    visit user_path user2
    find(".followB").click
  end

  it "should create a follow when a user clicks another's follow button" do
    user = User.find(user1.id)
    user.following_users.should include user2.id      #wtf
  end

  it "should display the followed user's posts in the follower's feed" do
    FactoryGirl.create(:talk, :user => user1, :content => "testy!")

  end
end