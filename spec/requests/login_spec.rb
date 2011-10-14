require 'spec_helper'

describe "Login", :js => true, :focus=>true do

  it "should sign in + get left sidebar" do
    user1 = FactoryGirl.create(:user)
    visit root_path
    click_link "Login"
    fill_in "Login", :with => user1.username
    fill_in "Password", :with => user1.password
    click_button :submit

    #TODO: figure out how to check if a user is logged in
    #session[:user_id].should == user1.id

    page.should have_selector("div.user-panel")
  end
end