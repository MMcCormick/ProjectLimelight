require 'spec_helper'

describe Talk do

  it "should create + persist a new instance given valid attributes" do
    FactoryGirl.create(:talk).should be_valid
  end

  it "should require content" do
    FactoryGirl.build(:talk, :content => "").should be_invalid
  end

  it "should reject content longer than 200 chars" do
    long_content = "blah " * 50
    FactoryGirl.build(:talk, :content => long_content).should be_invalid
  end

  it "should have a name attr equal to its content" do
    talk = FactoryGirl.build(:talk)
    talk.name.should == talk.content
  end

end