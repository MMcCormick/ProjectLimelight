require 'spec_helper'

describe LikesController do
  describe "POST create" do
    it "should click the login button when not signed in"

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      before(:each) { sign_in user }

      it "should respond with a 404 + json error object if the object is not found" do
        CoreObject.should_receive(:find).with("fooid").and_return(nil)
        xhr :post, :create, :id => "fooid"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 404
      end

      context "when object is found" do
        let(:object) { mock('object').as_null_object }
        before(:each) { CoreObject.should_receive(:find).with("fooid").and_return(object) }

        it "should call add_to_likes on the object" do
          object.should_receive(:add_to_likes).with(user)
          xhr :post, :create, :id => "fooid"
        end
        it "should save the current user and object" do
          object.should_receive(:save).and_return(true)
          controller.current_user.should_receive(:save)
          xhr :post, :create, :id => "fooid"
        end
        it "should respond with a json object, ok + with a target + toggle_classes" do
          xhr :post, :create, :id => "fooid"
          JSON.parse(response.body)['status'].should == "ok"
          JSON.parse(response.body)['target'].should_not be_blank
          JSON.parse(response.body)['toggle_classes'].should_not be_blank
        end
        it "should respond with a 201" do
          xhr :post, :create, :id => "fooid"
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

      it "should respond with a 404 + json error object if the object is not found" do
        CoreObject.should_receive(:find).with("fooid").and_return(nil)
        xhr :delete, :destroy, :id => "fooid"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 404
      end

      context "when object is found" do
        let(:object) { mock('object').as_null_object }
        before(:each) { CoreObject.should_receive(:find).with("fooid").and_return(object) }

        it "should call remove_from_likes on the object" do
          object.should_receive(:remove_from_likes).with(user)
          xhr :delete, :destroy, :id => "fooid"
        end
        it "should save the current user and object" do
          object.should_receive(:save).and_return(true)
          controller.current_user.should_receive(:save)
          xhr :delete, :destroy, :id => "fooid"
        end
        it "should respond with a json object, ok + with a target + toggle_classes" do
          xhr :delete, :destroy, :id => "fooid"
          JSON.parse(response.body)['status'].should == "ok"
          JSON.parse(response.body)['target'].should_not be_blank
          JSON.parse(response.body)['toggle_classes'].should_not be_blank
        end
        it "should respond with a 200" do
          xhr :delete, :destroy, :id => "fooid"
          response.response_code.should == 200
        end
      end
    end
  end
end