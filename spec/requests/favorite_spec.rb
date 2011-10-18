require 'spec_helper'

describe "Favorites" do
  include LoginHelper
  let(:user1) { FactoryGirl.create(:user) }

  it "should create a favorite when a user clicks an object's favorite button", :js=>true do
    talk = FactoryGirl.create(:talk, :content_raw => "yay content")
    sign_in_as user1
    visit root_path
    find(".favB").click
    user = User.find(user1.id)
    user.favorites.should include talk.id
  end

  it "should display the user's favorites in their favorites feed" do
    talk = FactoryGirl.create(:talk, :content_raw => "yay content")
    login_as user1
    xhr :post, create_favorite_path, :id => talk.id
    visit user_favorites_path user1
    page.should have_content "yay content"
  end
end