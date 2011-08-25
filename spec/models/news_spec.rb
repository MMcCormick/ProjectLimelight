require 'spec_helper'

describe News do

  before(:each) do
    @user = Factory(:user)
    @attr = {
      :title => "Example Title",
      :content => "Lorem epsom news content.",
    }
  end

  it "should create a new instance given a valid attribute" do
    @user.news.create!(@attr)
  end

  describe "validation rules" do
    it "should require nonblank title" do
      @user.news.build(:title => "  ").should_not be_valid
    end

    it "should require nonblank content" do
      @user.news.build(:content => "  ").should_not be_valid
    end

    it "should have a title max length of 100" do
      long_title = 'a' * 101
      news_with_long_title = News.new(@attr.merge(:title => long_title))
      news_with_long_title.should_not be_valid
    end

    it "should have a content max length of 400" do
      long_content = 'a' * 401
      news_with_long_content = News.new(@attr.merge(:content => long_content))
      news_with_long_content.should_not be_valid
    end
  end

  describe "user associations" do

    before(:each) do
      @news = @user.news.create(@attr)
    end

    it "should have a user attribute" do
      @news.should respond_to(:user)
    end

    it "should have the right associated user" do
      @news.user_id.should == @user.id
      @news.user.should == @user
    end

  end

end
