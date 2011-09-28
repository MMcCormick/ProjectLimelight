require 'spec_helper'

# Used talk, since core objects are never instantiated directly
# and talk is the least complex core object

describe CoreObject do
  it "should record user info correctly after set_user_snippet" do
    user = FactoryGirl.create(:user)
    talk = FactoryGirl.create(:talk)
    talk.set_user_snippet(user)
    talk.save
    talk.user_snippet.id.should == user.id
    talk.user_snippet.username.should == user.username
    talk.user_snippet._public_id.should == user._public_id
    talk.user_snippet.first_name.should == user.first_name
  end

  it "should set topic mentions correctly based on string sent to set_topic_mentions" do
    talk = FactoryGirl.create(:talk)
    talk.set_topic_mentions("foo1, foo 2,   foo 3    ")
    talk.topic_mentions[0].name.should == "foo1"
    talk.topic_mentions[1].name.should == "foo 2"
    talk.topic_mentions[2].name.should == "foo 3"
  end

  it "should set user mentions correctly based on content + users in db" do
    user = FactoryGirl.create(:user)
    talk = FactoryGirl.create(:talk, :content => "Foo [@#{user.username}]")
    talk.set_user_mentions()
    talk.user_mentions[0].username.should == user.username
  end
end