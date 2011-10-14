require 'spec_helper'

describe "HoverTabs", :js => true do
  it "loads hover tabs when hovering over a user link" do
    pending "figure out a better way to test js (Jasmine?)"
    talk = FactoryGirl.create(:talk)
    visit root_path
    ulink = page.find(:css, "a.ulink")
    # TODO: find a way to hover using capybara / selenium
    # ulink.native.hover()

  end
end
