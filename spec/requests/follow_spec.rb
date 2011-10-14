require 'spec_helper'

describe "Follows", :focus=>true do

  it "should create a follow when a user clicks another's follow button" do
    user1 = FactoryGirl.create(:user)

    login_as user1, :scope => :user

    visit root_path

    page.should have_selector("div.user-panel")

    # sign in
    #visit user_path user2
    #within(".user-panel") do
    #  click_button "Follow"
    #end
    #user1.following_users[0].id.should == user2.id
  end
end