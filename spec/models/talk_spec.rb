require 'spec_helper'

describe Talk do

  before(:each) do
    @user = Factory(:user)
    @attr = {
      :content => "Lorem epsom talk content.",
    }
  end

  it "should create a new instance given a valid attribute" do
    @user.talks.create!(@attr)
  end

  describe "validation rules" do
    it "should require nonblank title" do
      @user.talks.build(:title => "  ").should_not be_valid
    end

    it "should require nonblank content" do
      @user.talks.build(:content => "  ").should_not be_valid
    end

    it "should have a title max length of 100" do
      long_title = 'a' * 101
      talk_with_long_title = Talk.new(@attr.merge(:title => long_title))
      talk_with_long_title.should_not be_valid
    end

    it "should have a content max length of 400" do
      long_content = 'a' * 401
      talk_with_long_content = Talk.new(@attr.merge(:content => long_content))
      talk_with_long_content.should_not be_valid
    end
  end

  describe "user associations" do

    before(:each) do
      @talk = @user.talks.create(@attr)
    end

    it "should have a user attribute" do
      @talk.should respond_to(:user)
    end

    it "should have the right associated user" do
      @talk.user_id.should == @user.id
      @talk.user.should == @user
    end

  end

end
