require 'spec_helper'

describe Link do

  it "should create + persist a new instance given valid attributes" do
    FactoryGirl.create(:links).should be_valid
  end

  it "should require content" do
    FactoryGirl.build(:links, :content => "").should be_invalid
  end

  it "should reject content longer than 400 chars" do
    long_content = "blah " * 85
    FactoryGirl.build(:links, :content => long_content).should be_invalid
  end

  it "should reject content shorter than 5 chars" do
    FactoryGirl.build(:links, :content => "lala").should be_invalid
  end

  it "should reject titles longer than 100 chars" do
    long_title = "blah " * 25
    FactoryGirl.build(:links, :title => long_title).should be_invalid
  end

  it "should reject titles shorter than 5 chars" do
    FactoryGirl.build(:links, :title => "lala").should be_invalid
  end

  it "should have a name attr equal to its title" do
    link = FactoryGirl.build(:links)
    link.name.should == link.title
  end

  it "should require a url" do
    FactoryGirl.build(:links, :url => "").should be_invalid
  end

  #TODO: url validation
  it "should reject invalid urls" do
    pending "figure out url validation"
    FactoryGirl.build(:picture, :url => "http://poopypants").should be_invalid
    FactoryGirl.build(:picture, :url => "jump.ingjacks").should be_invalid
    FactoryGirl.build(:picture, :url => "this is an invalid url").should be_invalid
  end
end