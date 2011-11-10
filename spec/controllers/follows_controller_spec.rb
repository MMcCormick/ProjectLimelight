require 'spec_helper'

describe FollowsController do
  describe "POST create" do
    it "should click the login button when not signed in"

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      before(:each) { sign_in user }

      it "should respond with a 400 + json error object if params[:type] != 'User' or 'Topic'" do
        xhr :post, :create, :id => "fooid", :type => "notTopic"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 400
      end

      it "should call find on the appropriate model (User or Topic)" do
        Topic.should_receive(:find).with("fooid")
        xhr :post, :create, :id => "fooid", :type => "Topic"
        User.should_receive(:find).with("fooid")
        xhr :post, :create, :id => "fooid", :type => "User"
      end

      it "should respond with a 404 + json error object if the target is not found" do
        Topic.should_receive(:find).with("fooid").and_return(nil)
        xhr :post, :create, :id => "fooid", :type => "Topic"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 404
      end

      context "when target is found" do
        let(:target) { mock('target').as_null_object }
        before(:each) do
          Topic.should_receive(:find).with("fooid").and_return(target)
          controller.current_user.should_receive(:follow_object).with(target).and_return(true)
        end

        it "should call follow_object on the current user with target as arg" do
          xhr :post, :create, :id => "fooid", :type => "Topic"
        end
        it "should call add_pop_action on the target" do
          target.should_receive(:add_pop_action)
          xhr :post, :create, :id => "fooid", :type => "Topic"
        end
        it "should save the current user and target" do
          target.should_receive(:save)
          controller.current_user.should_receive(:save)
          xhr :post, :create, :id => "fooid", :type => "Topic"
        end
        it "should respond with a json object, ok + with a target + toggle_classes" do
          xhr :post, :create, :id => "fooid", :type => "Topic"
          JSON.parse(response.body)['status'].should == "ok"
          JSON.parse(response.body)['target'].should_not be_blank
          JSON.parse(response.body)['toggle_classes'].should_not be_blank
        end
        it "should respond with a 201" do
          xhr :post, :create, :id => "fooid", :type => "Topic"
          response.response_code.should == 201
        end
      end
    end
  end

  describe "DELETE destroy" do
    it "should click the login button when not signed in"

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      before(:each) { sign_in user }

      it "should respond with a 400 + json error object if params[:type] != 'User' or 'Topic'" do
        xhr :delete, :destroy, :id => "fooid", :type => "notTopic"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 400
      end

      it "should call find on the appropriate model (User or Topic)" do
        Topic.should_receive(:find).with("fooid")
        xhr :delete, :destroy, :id => "fooid", :type => "Topic"
        User.should_receive(:find).with("fooid")
        xhr :delete, :destroy, :id => "fooid", :type => "User"
      end

      it "should respond with a 404 + json error object if the target is not found" do
        Topic.should_receive(:find).with("fooid").and_return(nil)
        xhr :delete, :destroy, :id => "fooid", :type => "Topic"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 404
      end

      context "when target is found" do
        let(:target) { mock('target').as_null_object }
        before(:each) do
          Topic.should_receive(:find).with("fooid").and_return(target)
          controller.current_user.should_receive(:unfollow_object).with(target).and_return(true)
        end

        it "should call unfollow_object on the current user with target as arg" do
          xhr :delete, :destroy, :id => "fooid", :type => "Topic"
        end
        it "should save the current user and target" do
          target.should_receive(:save)
          controller.current_user.should_receive(:save)
          xhr :delete, :destroy, :id => "fooid", :type => "Topic"
        end
        it "should respond with a json object, ok + with a target + toggle_classes" do
          xhr :delete, :destroy, :id => "fooid", :type => "Topic"
          JSON.parse(response.body)['status'].should == "ok"
          JSON.parse(response.body)['target'].should_not be_blank
          JSON.parse(response.body)['toggle_classes'].should_not be_blank
        end
        it "should respond with a 201" do
          xhr :delete, :destroy, :id => "fooid", :type => "Topic"
          response.response_code.should == 201
        end
      end
    end
  end
end