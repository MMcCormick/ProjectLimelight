require 'spec_helper'

describe User do
  
  it "should create + persist a new instance given valid attributes" do
    FactoryGirl.create(:user).should be_valid
  end
  
  it "should require an email address" do
    FactoryGirl.build(:user, :email => "").
      should_not be_valid
  end
  
  it "should accept valid email addresses" do
    addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
    addresses.each do |address|
      FactoryGirl.build(:user, :email => address).
        should be_valid
    end
  end
  
  it "should reject invalid email addresses" do
    addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
    addresses.each do |address|
      FactoryGirl.build(:user, :email => address).
        should_not be_valid
    end
  end
  
  it "should reject duplicate email addresses" do
    user = FactoryGirl.create(:user)
    FactoryGirl.build(:user, :email => user.email).
      should_not be_valid
  end
  
  it "should reject email addresses identical up to case" do
    user = FactoryGirl.create(:user)
    FactoryGirl.build(:user, :email => user.email.upcase).
      should_not be_valid
  end

  it "should reject long usernames" do
    FactoryGirl.build(:user, :username => "thisisaverylongusernamethatisnotok").
      should_not be_valid
    end

  it "should reject short usernames" do
    FactoryGirl.build(:user, :username => "bo").
      should_not be_valid
  end

  it "should have a profile image after saving" do
    user = FactoryGirl.create(:user)
    user.should respond_to(:images)
  end

  describe "associations" do

    before(:each) do
      @user = FactoryGirl.build(:user)
    end

    it "should have core object attributes" do
      @user.should respond_to(:core_objects)
      @user.should respond_to(:news)
      @user.should respond_to(:videos)
      @user.should respond_to(:talks)
    end

    it "should have topic + topic type attributes" do
      @user.should respond_to(:topics)
      @user.should respond_to(:topic_types)
    end

  end

  describe "passwords" do

    before(:each) do
      @user = FactoryGirl.build(:user)
    end

    it "should have a password attribute" do
      @user.should respond_to(:password)
    end

    it "should have a password confirmation attribute" do
      @user.should respond_to(:password_confirmation)
    end
  end
  
  describe "password validations" do

    it "should require a password" do
      FactoryGirl.build(:user, :password => "", :password_confirmation => "").
        should_not be_valid
    end

    it "should require a matching password confirmation" do
      FactoryGirl.build(:user, :password_confirmation => "invalid").
        should_not be_valid
    end
    
    it "should reject short passwords" do
      FactoryGirl.build(:user, :password => "aaaaa", :password_confirmation => "aaaaa").
      should_not be_valid
    end
    
  end
  
  describe "password encryption" do
    
    before(:each) do
      @user = FactoryGirl.build(:user)
    end
    
    it "should have an encrypted password attribute" do
      @user.should respond_to(:encrypted_password)
    end

    it "should set the encrypted password attribute" do
      @user.encrypted_password.should_not be_blank
    end

  end

end