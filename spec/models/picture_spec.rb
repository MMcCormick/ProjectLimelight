require 'spec_helper'

describe Picture do

  it "should create + persist a new instance given valid attributes" do
    FactoryGirl.create(:picture).should be_valid
  end

  it "should not require content" do
    FactoryGirl.build(:picture, :content => "").should be_valid
  end

  it "should reject titles longer than 50 chars" do
    long_title = "blah " * 11
    FactoryGirl.build(:picture, :title => long_title).should be_invalid
  end

  it "should reject titles shorter than 5 chars" do
    FactoryGirl.build(:picture, :title => "lala").should be_invalid
  end

  it "should have a name attr equal to its title" do
    picture = FactoryGirl.build(:picture)
    picture.name.should == picture.title
  end

  it "should not require a url" do
    FactoryGirl.build(:picture, :url => nil).should be_valid
  end

  #TODO: url validation
  it "should reject invalid urls" do
    pending "figure out url validation"
    FactoryGirl.build(:picture, :url => "http://poopypants").should be_invalid
    FactoryGirl.build(:picture, :url => "jump.ingjacks").should be_invalid
    FactoryGirl.build(:picture, :url => "this is an invalid url").should be_invalid
  end
end