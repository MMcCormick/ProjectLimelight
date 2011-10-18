require 'spec_helper'

describe Topic do

  it "should create + persist a new instance given valid attributes" do
    FactoryGirl.create(:topic).should be_valid
  end

  it "should reject long names" do
    long_name = "blah " * 7
    FactoryGirl.build(:topic, :name => long_name).should_not be_valid
  end

  it "should reject short names" do
    FactoryGirl.build(:topic, :name => "a").should_not be_valid
  end

  it "should add an alias to itself before creating" do
    topic = FactoryGirl.create(:topic, :name => "topic name")
    topic.aliases.should include "topic-name"
  end
end