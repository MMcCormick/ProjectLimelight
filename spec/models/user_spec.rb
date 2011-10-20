require 'spec_helper'

describe User do
  #TODO: find_for_database_authentication
  
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
    FactoryGirl.build(:user, :username => "thisisaverylongusername").
      should_not be_valid
    end

  it "should reject short usernames" do
    FactoryGirl.build(:user, :username => "bo").
      should_not be_valid
  end

  it "should reject duplicate usernames" do
    FactoryGirl.create(:user, :username => "joey")
    FactoryGirl.build(:user, :username => "joey").
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

  #TODO: roles

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

  describe "following topics" do
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

  describe "favoriting" do
    let(:talk) { FactoryGirl.create(:talk) }
    let(:user) { FactoryGirl.create(:user) }

    it "should respond correctly to has_favorite?" do
      user.has_favorite?(talk.id).should_not be_true
      user.add_to_favorites(talk)
      user.has_favorite?(talk.id).should be_true
    end

    context "when the user has not already favorited the object" do
      describe "add_to_favorites" do
        it "should record the object and update count when passed a valid object" do
          expect {
            user.add_to_favorites(talk)
          }.to change(user, :favorites_count).by(1)
          user.favorites.should include(talk.id)
          user.save
        end
      end
      describe "remove_from_favorites" do
        it "should do nothing" do
          expect {
            talk.remove_from_favorites(user)
          }.to_not change(user, :favorites_count)
          user.favorites.should_not include(talk.id)
        end
      end
    end

    context "when the user has already favorited the object" do
      before(:each) do
        user.add_to_favorites(talk)
      end

      describe "add_to_favorites" do
        it "should not change count" do
          expect {
            user.add_to_favorites(talk)
          }.to_not change(user, :favorites_count)
        end
        it "should keep the user recorded" do
          user.add_to_favorites(talk)
          user.favorites.should include(talk.id)
        end
      end
      describe "remove_from_favorites" do
        it "should remove the user and update count" do
          expect {
            user.remove_from_favorites(talk)
          }.to change(user, :favorites_count).by(-1)
          user.favorites.should_not include(talk.id)
        end
      end
    end
  end

  describe "update_denorms" do
    let(:user) { FactoryGirl.create(:user) }

    it "should update CoreObject.user_snippets when attributes are updated" do
      talk = FactoryGirl.create(:talk, :user => user)
      talk.user_snippet.username.should == user.username
      user.update_attributes(:username => "jamie", :first_name => "james", :last_name => "michaels")
      updated_talk = Talk.find(talk.id)
      updated_talk.user_snippet.username.should == "jamie"
      updated_talk.user_snippet.first_name.should == "james"
      updated_talk.user_snippet.last_name.should == "michaels"
    end
    it "should update CoreObject.user_mentions when attributes are updated" do
      talk = FactoryGirl.create(:talk, :content_raw => "mentioning @[#{user.id}##{user.username}]")
      talk.user_mentions[0].username.should == user.username
      user.update_attributes(:username => "jamie", :first_name => "james", :last_name => "michaels")
      updated_talk = Talk.find(talk.id)
      updated_talk.user_mentions[0].username.should == "jamie"
      updated_talk.user_mentions[0].first_name.should == "james"
      updated_talk.user_mentions[0].last_name.should == "michaels"
    end
    it "should update Topic.user_snippets when attributes are updated" do
      topic = FactoryGirl.create(:topic, :user => user)
      topic.user_snippet.username.should == user.username
      user.update_attributes(:username => "jamie", :first_name => "james", :last_name => "michaels")
      updated_topic = Topic.find(topic.id)
      updated_topic.user_snippet.username.should == "jamie"
      updated_topic.user_snippet.first_name.should == "james"
      updated_topic.user_snippet.last_name.should == "michaels"
    end
    it "should update Comment.user_snippets when attributes are updated" do
      comment = FactoryGirl.create(:comment, :user => user)
      comment.user_snippet.username.should == user.username
      user.update_attributes(:username => "jamie", :first_name => "james", :last_name => "michaels")
      updated_comment = Comment.find(comment.id)
      updated_comment.user_snippet.username.should == "jamie"
      updated_comment.user_snippet.first_name.should == "james"
      updated_comment.user_snippet.last_name.should == "michaels"
    end

    #TODO: notifications
  end
end