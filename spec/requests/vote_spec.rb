require 'spec_helper'

describe "Votes" do
  include LoginHelper
  let(:user1) { FactoryGirl.create(:user) }

  it "should change object's vote count appropriately when the vote buttons are clicked", :js=>true do
    talk = FactoryGirl.create(:talk, :content_raw => "yay content")
    talk.votes_count.should == 0
    sign_in_as user1
    visit root_path
    find(".voteB.up").click
    talk = Talk.find(talk.id)
    talk.votes_count.should == 1
    find(".voteB.down").click
    talk = Talk.find(talk.id)
    talk.votes_count.should == -1
  end
end