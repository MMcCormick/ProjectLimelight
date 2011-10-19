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

  describe "update_denorms" do
    let(:topic) { FactoryGirl.create(:topic) }

    it "should update CoreObject.topic_mentions when name is updated" do
      talk = FactoryGirl.create(:talk, :content_raw => "mentioning #[#{topic.id}##{topic.name}]")
      talk.topic_mentions[0].name.should == topic.name
      topic.update_attributes(:name => "new name")
      updated_talk = Talk.find(talk.id)
      updated_talk.topic_mentions[0].name.should == "new name"
      updated_talk.topic_mentions[0].slug.should == "new-name"
    end
    it "should update the topic's aliases when name is updated" do
      topic.aliases.should include topic.name
      topic.update_attributes(:name => "new name")
      topic.aliases.should include "new-name"
    end
  end
end