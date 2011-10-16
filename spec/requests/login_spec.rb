require 'spec_helper'

#Method for non-js logins: login_as user1, :scope => :user

describe "Login", :js => true do

  it "should sign in + get left sidebar" do
    user1 = FactoryGirl.create(:user)
    visit root_path
    click_link "Login"
    fill_in "Login", :with => user1.username
    fill_in "Password", :with => user1.password
    click_button :submit

    within("div.user-panel") do
      page.should have_content(user1.username)
    end  end
end