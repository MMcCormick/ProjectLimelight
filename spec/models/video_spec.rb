require 'spec_helper'

describe Video do

  it "should create + persist a new instance given valid attributes" do
    FactoryGirl.create(:video).should be_valid
  end

  it "should not require content" do
    FactoryGirl.build(:video, :content => "").should be_valid
  end

  it "should reject titles longer than 50 chars" do
    long_title = "blah " * 11
    FactoryGirl.build(:video, :title => long_title).should be_invalid
  end

  it "should reject titles shorter than 5 chars" do
    FactoryGirl.build(:video, :title => "lala").should be_invalid
  end

  it "should have a name attr equal to its title" do
    video = FactoryGirl.build(:video)
    video.name.should == video.title
  end

  it "should require a url" do
    FactoryGirl.build(:video, :url => nil).should_not be_valid
  end

  it "should require a provider name" do
    FactoryGirl.build(:video, :provider_name => "").should_not be_valid
  end

  it "should require a provider video id" do
    FactoryGirl.build(:video, :url => "").should_not be_valid
  end

  it "should reject invalid urls" do
    pending "figure out url validation"
    FactoryGirl.build(:video, :url => "http://poopypants").should be_invalid
    FactoryGirl.build(:video, :url => "jump.ingjacks").should be_invalid
    FactoryGirl.build(:video, :url => "this is an invalid url").should be_invalid
  end
end