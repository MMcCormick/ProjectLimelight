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

  describe "following users" do
    let(:this_user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }

    describe "is_following_user?" do
      it "should return true when following" do
        this_user.follow_user(other_user)
        this_user.is_following_user?(other_user.id).should be_true
      end
      it "should return false when not following" do
        this_user.is_following_user?(other_user.id).should be_false
      end
    end
    describe "follow_user" do
      context "when not already following" do
        it "should update this user's following_users_count" do
          expect {
            this_user.follow_user(other_user)
          }.to change(this_user, :following_users_count).by(1)
        end
        it "should update the followed user's followers_count" do
          expect {
            this_user.follow_user(other_user)
          }.to change(other_user, :followers_count).by(1)
        end
        it "should insert the followed user's id into following_users" do
          this_user.follow_user(other_user)
          this_user.following_users.should include(other_user.id)
        end
      end
      context "when already following" do
        before(:each) { this_user.follow_user(other_user) }

        it "should not update this user's following_users_count" do
          expect {
            this_user.follow_user(other_user)
          }.to_not change(this_user, :following_users_count)
        end
        it "should not update the followed user's followers_count" do
          expect {
            this_user.follow_user(other_user)
          }.to_not change(other_user, :followers_count)
        end
        it "should still have the followed user's id in following_users" do
          this_user.follow_user(other_user)
          this_user.following_users.should include(other_user.id)
        end
      end
    end
    describe "unfollow_user" do
      context "when not already following" do
        it "should not update this user's following_users_count" do
          expect {
            this_user.unfollow_user(other_user)
          }.to_not change(this_user, :following_users_count)
        end
        it "should not update the unfollowed user's followers_count" do
          expect {
            this_user.unfollow_user(other_user)
          }.to_not change(other_user, :followers_count)
        end
        it "should still not have the unfollowed user's id in following_users" do
          this_user.unfollow_user(other_user)
          this_user.following_users.should_not include(other_user.id)
        end
      end
      context "when already following" do
        before(:each) { this_user.follow_user(other_user) }
        it "should update this user's following_users_count" do
          expect {
            this_user.unfollow_user(other_user)
          }.to change(this_user, :following_users_count).by(-1)
        end
        it "should update the unfollowed user's followers_count" do
          expect {
            this_user.unfollow_user(other_user)
          }.to change(other_user, :followers_count).by(-1)
        end
        it "should remove the unfollowed user's id from following_users" do
          this_user.unfollow_user(other_user)
          this_user.following_users.should_not include(other_user.id)
        end
      end
    end
  end

  describe "following topics", :focus=>true do
    let(:this_user) { FactoryGirl.create(:user) }
    let(:topic) { FactoryGirl.create(:topic) }

    describe "is_following_topic?" do
      it "should return true when following" do
        this_user.follow_topic(topic)
        this_user.is_following_topic?(topic.id).should be_true
      end
      it "should return false when not following" do
        this_user.is_following_topic?(topic.id).should be_false
      end
    end
    describe "follow_topic" do
      context "when not already following" do
        it "should update this user's following_topics_count" do
          expect {
            this_user.follow_topic(topic)
          }.to change(this_user, :following_topics_count).by(1)
        end
        it "should update the followed topic's followers_count" do
          expect {
            this_user.follow_topic(topic)
          }.to change(topic, :followers_count).by(1)
        end
        it "should insert the followed topic's id into following_topics" do
          this_user.follow_topic(topic)
          this_user.following_topics.should include(topic.id)
        end
      end
      context "when already following" do
        before(:each) { this_user.follow_topic(topic) }

        it "should not update this user's following_topics_count" do
          expect {
            this_user.follow_topic(topic)
          }.to_not change(this_user, :following_topics_count)
        end
        it "should not update the followed topic's followers_count" do
          expect {
            this_user.follow_topic(topic)
          }.to_not change(topic, :followers_count)
        end
        it "should still have the followed topic's id in following_topics" do
          this_user.follow_topic(topic)
          this_user.following_topics.should include(topic.id)
        end
      end
    end
    describe "unfollow_topic" do
      context "when not already following" do
        it "should not update this user's following_topics_count" do
          expect {
            this_user.unfollow_topic(topic)
          }.to_not change(this_user, :following_topics_count)
        end
        it "should not update the unfollowed topic's followers_count" do
          expect {
            this_user.unfollow_topic(topic)
          }.to_not change(topic, :followers_count)
        end
        it "should still not have the unfollowed topic's id in following_topics" do
          this_user.unfollow_topic(topic)
          this_user.following_topics.should_not include(topic.id)
        end
      end
      context "when already following" do
        before(:each) { this_user.follow_topic(topic) }
        it "should update this user's following_topics_count" do
          expect {
            this_user.unfollow_topic(topic)
          }.to change(this_user, :following_topics_count).by(-1)
        end
        it "should update the unfollowed topic's followers_count" do
          expect {
            this_user.unfollow_topic(topic)
          }.to change(topic, :followers_count).by(-1)
        end
        it "should remove the unfollowed topic's id from following_topics" do
          this_user.unfollow_topic(topic)
          this_user.following_topics.should_not include(topic.id)
        end
      end
    end
  end
end