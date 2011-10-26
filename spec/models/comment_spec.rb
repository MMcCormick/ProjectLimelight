require 'spec_helper'

describe Comment do

  it "should create + persist a new instance given valid attributes" do
    FactoryGirl.create(:comment).should be_valid
  end

  it "should require content" do
    FactoryGirl.build(:comment, :content => "").should be_invalid
  end

  it "should reject content longer than 150 chars" do
    long_content = "blah " * 35
    FactoryGirl.build(:comment, :content => long_content).should be_invalid
  end

  it "should reject content shorter than 3 chars" do
    FactoryGirl.build(:comment, :content => "la").should be_invalid
  end

  it "should reject comments with depth > 5" do
    FactoryGirl.build(:comment, :depth => 6).should be_invalid
  end

  it "should update associated talk's comments count after creation" do
    talk = FactoryGirl.create(:talk)
    FactoryGirl.create(:comment, :talk => talk)
    talk.comments_count.should == 1
  end
end