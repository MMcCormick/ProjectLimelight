require 'spec_helper'

# Used talk, since core objects are never instantiated directly
# and talk is the least complex core object

describe CoreObject do

  describe "core object creation" do
    it "should require a user_id" do
      FactoryGirl.build(:talk, :user_id => "").should_not be_valid
    end

    #TODO: now
    it "should set topic mentions" do
      pending "should create a new topic if #[topic name] included in content_raw"
      pending "should not create a new topic if #[id#name] included in content_raw"
      pending "should create topic snippets for each #[topic name] included in content raw"
      pending "should create topic snippets for each #[id#name] included in content raw"
      pending "should not create duplicate topic snippets if a topic is mentioned twice"
    end

    #TODO: now
    it "should set user mentions" do
      pending "should create a user mentions for each @[id#username] included in content_raw"
      pending "should not create a user mention if @[fake id#username] included in content raw"
    end

    # OLD
    #it "should set topic mentions correctly based on string sent to set_topic_mentions" do
    #  talk = FactoryGirl.create(:talk, :tagged_topics => "foo1, foo 2,   foo 3    ")
    #  talk.topic_mentions[0].name.should == "foo1"
    #  talk.topic_mentions[1].name.should == "foo 2"
    #  talk.topic_mentions[2].name.should == "foo 3"
    #end
    #
    #context "based on user" do
    #  let(:user) { FactoryGirl.create(:user) }
    #
    #  it "should record user_snippet info correctly" do
    #    talk = FactoryGirl.create(:talk, :user => user)
    #    talk.user_snippet.id.should == user.id
    #    talk.user_snippet.username.should == user.username
    #    talk.user_snippet._public_id.should == user._public_id
    #    talk.user_snippet.first_name.should == user.first_name
    #  end
    #
    #  it "should set user mentions correctly based on content + users in db" do
    #    talk = FactoryGirl.create(:talk, :content => "Foo [@#{user.username}]")
    #    talk.user_mentions[0].username.should == user.username
    #    talk.user_mentions[0].first_name.should == user.first_name
    #    talk.user_mentions[0].last_name.should == user.last_name
    #    talk.user_mentions[0].username.should == user.username
    #  end
    #end
  end

  describe "to_param" do
    it "should return an encoded id followed by a name slug from to_param" do
      talk = FactoryGirl.create(:talk, :content_raw => "foo bar")
      talk.to_param.should == talk._public_id.to_i.to_s(36) + "-foo-bar"
    end
  end

  describe "find_by_encoded_id" do
    it "should return the correct object when passed a valid encoded id" do
      pending "figure out why equal? doesn't return true even though they're the same object"
      talk = FactoryGirl.create(:talk)
      Talk.find_by_encoded_id(talk._public_id.to_i.to_s(36)).should equal(talk)
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

  describe "favoriting", :focus=>true do
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
            talk.add_to_favorites(user)
          }.to change(talk, :favorites_count).by(1)
          talk.favorites.should include(user.id)
          talk.save
        end
      end
      describe "remove_from_favorites" do
        it "should do nothing" do
          user.should_not_receive(:remove_from_favorites)
          expect {
            talk.remove_from_favorites(user)
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
            talk.add_to_favorites(user)
          }.to_not change(talk, :favorites_count)
        end
        it "should keep the user recorded" do
          talk.add_to_favorites(user)
          talk.favorites.should include(user.id)
        end
      end
      describe "remove_from_favorites" do
        it "should remove the user and update count" do
          user.should_receive(:remove_from_favorites)
          expect {
            talk.remove_from_favorites(user)
          }.to change(talk, :favorites_count).by(-1)
          talk.favorites.should_not include(user.id)
        end
      end
    end
  end

  describe "reposting" do
    let(:talk) { FactoryGirl.create(:talk) }
    let(:user) { FactoryGirl.create(:user) }

    it "should respond correctly to reposted_by?" do
      talk.reposted_by?(user.id).should_not be_true
      talk.add_to_reposts(user)
      talk.reposted_by?(user.id).should be_true
    end

    context "when the user has not already reposted the object" do
      describe "add_to_reposts" do
        it "should record the user and update counts when passed a valid user" do
          expect {
            expect {
              talk.add_to_reposts(user)
            }.to change(user, :reposts_count).by(1)
          }.to change(talk, :reposts_count).by(1)
          talk.reposts.should include(user.id)
        end
      end
      describe "remove_from_reposts" do
        it "should do nothing" do
          expect {
            expect {
              talk.remove_from_reposts(user)
            }.to_not change(user, :reposts_count)
          }.to_not change(talk, :reposts_count)
          talk.reposts.should_not include(user.id)
        end
      end
    end

    context "when the user has already reposted the object" do
      before(:each) do
        talk.add_to_reposts(user)
      end

      describe "add_to_reposts" do
        it "should not change counts" do
          expect {
            expect {
              talk.add_to_reposts(user)
            }.to_not change(user, :reposts_count)
          }.to_not change(talk, :reposts_count)
        end
        it "should keep the user recorded" do
          talk.add_to_reposts(user)
          talk.reposts.should include(user.id)
        end
      end
      describe "remove_from_reposts" do
        it "should remove the user and update counts" do
          expect {
            expect {
              talk.remove_from_reposts(user)
            }.to change(user, :reposts_count).by(-1)
          }.to change(talk, :reposts_count).by(-1)
          talk.reposts.should_not include(user.id)
        end
      end
    end
  end

  #TODO: feed
  describe "feed" do
    it "should take care of basically every piece of feed logic, fml" do

    end
  end
end