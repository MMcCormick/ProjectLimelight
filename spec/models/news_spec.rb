require 'spec_helper'

describe News do

  it "should create + persist a new instance given valid attributes" do
    FactoryGirl.create(:news).should be_valid
  end

  it "should require content" do
    FactoryGirl.build(:news, :content => "").should be_invalid
  end

  it "should reject content longer than 400 chars" do
    long_content = "blah " * 85
    FactoryGirl.build(:news, :content => long_content).should be_invalid
  end

  it "should reject content shorter than 5 chars" do
    FactoryGirl.build(:news, :content => "lala").should be_invalid
  end

  it "should reject titles longer than 100 chars" do
    long_title = "blah " * 25
    FactoryGirl.build(:news, :title => long_title).should be_invalid
  end

  it "should reject titles shorter than 5 chars" do
    FactoryGirl.build(:news, :title => "lala").should be_invalid
  end

  it "should have a name attr equal to its title" do
    news = FactoryGirl.build(:news)
    news.name.should == news.title
  end

  it "should require a url" do
    FactoryGirl.build(:news, :url => "").should be_invalid
  end

  #TODO: url validation
  it "should reject invalid urls" do
    pending "figure out url validation"
    FactoryGirl.build(:picture, :url => "http://poopypants").should be_invalid
    FactoryGirl.build(:picture, :url => "jump.ingjacks").should be_invalid
    FactoryGirl.build(:picture, :url => "this is an invalid url").should be_invalid
  end
end