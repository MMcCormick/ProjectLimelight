require 'spec_helper'

describe Vote do

  it "should only allow vote amounts between -1 and 1" do
    FactoryGirl.build(:vote, :amount => 2).should_not be_valid
    FactoryGirl.build(:vote, :amount => -2).should_not be_valid
    FactoryGirl.build(:vote, :amount => 1).should be_valid
    FactoryGirl.build(:vote, :amount => 0).should be_valid
    FactoryGirl.build(:vote, :amount => -1).should be_valid
  end
end