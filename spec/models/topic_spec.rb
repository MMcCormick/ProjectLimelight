require 'spec_helper'

describe Topic do

  # TODO: now
  it "should create + persist a new instance given valid attributes"

  it "should require an email address" do
    FactoryGirl.build(:user, :email => "").
      should_not be_valid
  end

  # TODO: now
  it "should reject long names"

  # TODO: now
  it "should reject short names"

  # TODO: now
  it "should add an alias to itself before creating"

end