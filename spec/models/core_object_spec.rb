require 'spec_helper'

# Used talk, since core objects are never instantiated directly
# and talk is the least complex core object

describe CoreObject do

  describe "core object creation" do
    it "should require a user_id" do
      FactoryGirl.build(:talk, :user_id => "").should_not be_valid
    end

    describe "setting topic mentions" do
      it "should create a new topic if #[topic name] included in content_raw" do
        expect {
          FactoryGirl.create(:talk, :content_raw => "this is #[foobar]")
        }.to change(Topic, :count).by(1)
        expect {
          FactoryGirl.create(:talk, :content_raw => "this is #[poobar] #[doobar]")
        }.to change(Topic, :count).by(2)
      end
      it "should not create a new topic if #[id#name] included in content_raw" do
        topic = FactoryGirl.create(:topic, :name => "foo")
        expect {
          FactoryGirl.create(:talk, :content_raw => "this is #[#{topic.id}#foo]")
        }.to_not change(Topic, :count)
      end
      it "should create topic snippets for each #[topic name] included in content raw" do
        talk = FactoryGirl.create(:talk, :content_raw => "this is #[foobar] #[doobar]")
        talk.topic_mentions.detect { |snippet| snippet.name == "foobar" }.should_not be_nil
        talk.topic_mentions.detect { |snippet| snippet.name == "doobar" }.should_not be_nil
        talk.topic_mentions.detect { |snippet| snippet.name == "zoobar" }.should be_nil
      end
      it "should create topic snippets for each #[id#name] included in content raw" do
        topic = FactoryGirl.create(:topic, :name => "foo")
        topic2 = FactoryGirl.create(:topic, :name => "doo")
        talk = FactoryGirl.create(:talk, :content_raw => "this is #[#{topic.id}#foo] #[#{topic2.id}#doo]")
        talk.topic_mentions.detect { |snippet| snippet.name == "foo" }.should_not be_nil
        talk.topic_mentions.detect { |snippet| snippet.name == "doo" }.should_not be_nil
        talk.topic_mentions.detect { |snippet| snippet.name == "zoobar" }.should be_nil
      end
      it "should not create duplicate topic snippets if a topic is mentioned twice" do
        topic = FactoryGirl.create(:topic, :name => "foo")
        talk = FactoryGirl.create(:talk, :content_raw => "this is #[#{topic.id}#foo] #[#{topic.id}#foo]")
        talk.topic_mentions.count.should == 1
      end
    end

    describe "setting user mentions" do
      it "should create a user mentions for each @[id#username] included in content_raw" do
        user = FactoryGirl.create(:user, :username => "foouser")
        user2 = FactoryGirl.create(:user, :username => "doouser")
        talk = FactoryGirl.create(:talk, :content_raw => "this is @[#{user.id}#foouser] @[#{user2.id}#doouser]")
        talk.user_mentions.detect { |snippet| snippet.username == "foouser" }.should_not be_nil
        talk.user_mentions.detect { |snippet| snippet.username == "doouser" }.should_not be_nil
        talk.user_mentions.detect { |snippet| snippet.username == "zoobar" }.should be_nil
      end
      it "should not create a user mention if @[fake id#username] included in content raw" do
        talk = FactoryGirl.create(:talk, :content_raw => "this is @[132826132#foouser]")
        talk.user_mentions.should be_empty
      end
    end
  end

  describe "to_param" do
    it "should return an encoded id followed by a name slug from to_param" do
      talk = FactoryGirl.create(:talk, :content_raw => "foo bar")
      talk.to_param.should == talk.encoded_id + "-foo-bar"
    end
  end

  describe "find_by_encoded_id" do
    it "should return the correct object when passed a valid encoded id" do
      pending "figure out why equal? doesn't return true even though they're the same object"
      talk = FactoryGirl.create(:talk)
      Talk.find_by_encoded_id(talk.encoded_id).should equal(talk)
    end
  end

  describe "add_voter" do
    let(:talk) { FactoryGirl.create(:talk) }
    let(:user) { FactoryGirl.create(:user) }

    context "when the user has not voted on the object" do
      it "should add a new vote in the amount passed" do
        talk.add_voter(user, 3)
        talk.votes[0].id.should == user.id
        talk.votes[0].amount.should == 3
      end
      it "should change the user vote count" do
        expect {
          talk.add_voter(user, 3)
        }.to change(user, :vote_pos_count).by(1)
      end
      it "should change the talk vote count" do
        expect {
          talk.add_voter(user, 3)
        }.to change(talk, :votes_count).by(3)
      end
    end

    context "when the user has voted on the object" do
      before(:each) do
        talk.add_voter(user, 1)
      end

      it "should add a new vote in the amount passed" do
        talk.add_voter(user, -2)
        talk.votes[0].id.should == user.id
        talk.votes[0].amount.should == -2
      end
      it "should change the user vote counts (pos and neg)" do
        expect {
          expect {
            talk.add_voter(user, -2)
          }.to change(user, :vote_neg_count).by(1)
        }.to change(user, :vote_pos_count).by(-1)
      end
      it "should change talk vote count" do
        expect {
          talk.add_voter(user, -2)
        }.to change(talk, :votes_count).by(-3)
      end
    end
  end

  describe "remove_voter" do
    let(:talk) { FactoryGirl.create(:talk) }
    let(:user) { FactoryGirl.create(:user) }

    context "when the user has not voted on the object" do
      it "should not change user vote count on a call to remove_voter" do
        expect {
          talk.remove_voter(user)
        }.to_not change(user, :vote_pos_count)
      end
      it "should not change talk vote count on a call to remove_voter" do
        expect {
          talk.remove_voter(user)
        }.to_not change(talk, :votes_count)
      end
    end

    context "when the user has voted on the object" do
      before(:each) do
        talk.add_voter(user, 1)
      end
      it "should update the user's vote counts appropriately'" do
        expect {
          talk.remove_voter(user)
        }.to change(user, :vote_pos_count).by(-1)
      end
    end
  end

  describe "favoriting" do
    let(:talk) { FactoryGirl.create(:talk) }
    let(:user) { FactoryGirl.create(:user) }

    it "should respond correctly to favorited_by?" do
      talk.favorited_by?(user.id).should_not be_true
      talk.add_to_favorites(user)
      talk.favorited_by?(user.id).should be_true
    end

    context "when the user has not already favorited the object" do
      describe "add_to_favorites" do
        it "should record the user, update count, and call user.add_to_favorites when passed a valid user" do
          user.should_receive(:add_to_favorites)
          expect {
            talk.add_to_favorites(user).should be_true
          }.to change(talk, :favorites_count).by(1)
          talk.favorites.should include(user.id)
          talk.save
        end
      end
      describe "remove_from_favorites" do
        it "should do nothing" do
          user.should_not_receive(:remove_from_favorites)
          expect {
            talk.remove_from_favorites(user).should be_false
          }.to_not change(talk, :favorites_count)
          talk.favorites.should_not include(user.id)
        end
      end
    end

    context "when the user has already favorited the object" do
      before(:each) do
        talk.add_to_favorites(user)
      end

      describe "add_to_favorites" do
        it "should do nothing" do
          user.should_not_receive(:add_to_favorites)
          expect {
            talk.add_to_favorites(user).should be_false
          }.to_not change(talk, :favorites_count)
        end
        it "should keep the user recorded" do
          talk.add_to_favorites(user).should be_false
          talk.favorites.should include(user.id)
        end
      end
      describe "remove_from_favorites" do
        it "should remove the user and update count" do
          user.should_receive(:remove_from_favorites)
          expect {
            talk.remove_from_favorites(user).should be_true
          }.to change(talk, :favorites_count).by(-1)
          talk.favorites.should_not include(user.id)
        end
      end
    end
  end

  describe "liking" do
    let(:talk) { FactoryGirl.create(:talk) }
    let(:user) { FactoryGirl.create(:user) }

    it "should respond correctly to liked_by?" do
      talk.liked_by?(user.id).should_not be_true
      talk.add_to_likes(user)
      talk.liked_by?(user.id).should be_true
    end

    it "should not allow a user to like their own objects" do
      talk2 = FactoryGirl.create(:talk, :user => user)
      expect {
        expect {
          talk2.add_to_likes(user).should be_false
        }.to_not change(user, :likes_count)
      }.to_not change(talk, :likes_count)
      talk.likes.should_not include(user.id)
    end

    context "when the user has not already liked the object" do
      describe "add_to_likes" do
        it "should record the user and update counts when passed a valid user" do
          expect {
            expect {
              talk.add_to_likes(user).should be_true
            }.to change(user, :likes_count).by(1)
          }.to change(talk, :likes_count).by(1)
          talk.likes.should include(user.id)
        end
      end
      describe "remove_from_likes" do
        it "should do nothing" do
          expect {
            expect {
              talk.remove_from_likes(user).should be_false
            }.to_not change(user, :likes_count)
          }.to_not change(talk, :likes_count)
          talk.likes.should_not include(user.id)
        end
      end
    end

    context "when the user has already liked the object" do
      before(:each) do
        talk.add_to_likes(user)
      end

      describe "add_to_likes" do
        it "should not change counts" do
          expect {
            expect {
              talk.add_to_likes(user).should be_false
            }.to_not change(user, :likes_count)
          }.to_not change(talk, :likes_count)
        end
        it "should keep the user recorded" do
          talk.add_to_likes(user).should be_false
          talk.likes.should include(user.id)
        end
      end
      describe "remove_from_likes" do
        it "should remove the user and update counts" do
          expect {
            expect {
              talk.remove_from_likes(user).should be_true
            }.to change(user, :likes_count).by(-1)
          }.to change(talk, :likes_count).by(-1)
          talk.likes.should_not include(user.id)
        end
      end
    end
  end

  #TODO: feed
  describe "feed" do
    it "should take care of basically every piece of feed logic, fml" do
      pending "later"
    end
  end
end