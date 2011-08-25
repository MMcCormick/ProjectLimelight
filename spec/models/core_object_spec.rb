require 'spec_helper'

describe CoreObject do

  before(:each) do
    @user = Factory(:user)
    @attr = {
      :title => "Example Title",
      :content => "Lorem epsom news content.",
    }
  end

  it "should create a new instance given a valid attribute" do
    @user.core_objects.create!(@attr)
  end

  describe "validation rules" do

    it "should require a user id" do
      CoreObject.new(@attr).should_not be_valid
    end

  end

  describe "user associations" do

    before(:each) do
      @core_object = @user.core_objects.create(@attr)
    end

    it "should have a user attribute" do
      @core_object.should respond_to(:user)
    end

    it "should have the right associated user" do
      @core_object.user_id.should == @user.id
      @core_object.user.should == @user
    end

  end

end
