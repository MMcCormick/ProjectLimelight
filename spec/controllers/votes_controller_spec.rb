require 'spec_helper'

describe VotesController do
  describe "POST create" do
    it "should click the login button when not signed in"

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      before(:each) { sign_in user }

      it "should respond with a 400 + json error object if type is not acceptable" do
        xhr :post, :create, :id => "fooid", :type => "notAnything"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 400
      end

      it "should respond with a 404 + json error object if the object is not found" do
        Talk.should_receive(:find).with("fooid").and_return(nil)
        xhr :post, :create, :id => "fooid", :type => "Talk"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 404
      end

      context "when object is found" do
        let(:object) { mock('object').as_null_object }
        before(:each) { Talk.should_receive(:find).with("fooid").and_return(object) }

        it "should respond with a 404 + json error object if the amount is > 1" do
          xhr :post, :create, :id => "fooid", :a => "2", :type => "Talk"
          JSON.parse(response.body)['status'].should == "error"
          response.response_code.should == 404
        end
        it "should respond with a 404 + json error object if the amount is < -1" do
          xhr :post, :create, :id => "fooid", :a => "-2", :type => "Talk"
          JSON.parse(response.body)['status'].should == "error"
          response.response_code.should == 404
        end
        it "should respond with a 401 + json error object if the user owns the object" do
          object.should_receive(:user_id).and_return(user.id)
          xhr :post, :create, :id => "fooid", :type => "Talk"
          JSON.parse(response.body)['status'].should == "error"
          response.response_code.should == 401
        end
        it "should call add_voter on the object with the current user and amount passed" do
          object.should_receive(:add_voter).with(user, 1)
          xhr :post, :create, :id => "fooid", :a => "1", :type => "Talk"
        end
        it "should save the current user and object" do
          object.should_receive(:save!).and_return(true)
          controller.current_user.should_receive(:save!)
          xhr :post, :create, :id => "fooid", :type => "Talk"
        end
        it "should respond with a json object, :ok with an :id and :amount" do
          xhr :post, :create, :id => "fooid", :type => "Talk"
          JSON.parse(response.body)['status'].should == "ok"
          JSON.parse(response.body)['id'].should_not be_blank
          JSON.parse(response.body)['a'].should_not be_blank
        end
        it "should respond with a 201" do
          xhr :post, :create, :id => "fooid", :type => "Talk"
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

      it "should respond with a 400 + json error object if type is not acceptable" do
        xhr :post, :create, :id => "fooid", :type => "notAnything"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 400
      end

      it "should respond with a 404 + json error object if the object is not found" do
        Talk.should_receive(:find).with("fooid").and_return(nil)
        xhr :delete, :destroy, :id => "fooid", :type => "Talk"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 404
      end

      context "when object is found" do
        let(:object) { mock('object').as_null_object }
        before(:each) { Talk.should_receive(:find).with("fooid").and_return(object) }

        it "should respond with a 401 + json error object if the user owns the object" do
          object.should_receive(:user_id).and_return(user.id)
          xhr :delete, :destroy, :id => "fooid", :type => "Talk"
          JSON.parse(response.body)['status'].should == "error"
          response.response_code.should == 401
        end
        it "should call remove_voter on the object with the current user" do
          object.should_receive(:remove_voter).with(user)
          xhr :delete, :destroy, :id => "fooid", :type => "Talk"
        end
        it "should save the current user and object" do
          object.should_receive(:save!).and_return(true)
          controller.current_user.should_receive(:save!)
          xhr :delete, :destroy, :id => "fooid", :type => "Talk"
        end
        it "should respond with a json object, :ok with an :id and :amount" do
          xhr :delete, :destroy, :id => "fooid", :type => "Talk"
          JSON.parse(response.body)['status'].should == "ok"
          JSON.parse(response.body)['id'].should_not be_blank
          JSON.parse(response.body)['a'].should_not be_blank
        end
        it "should respond with a 200" do
          xhr :delete, :destroy, :id => "fooid", :type => "Talk"
          response.response_code.should == 200
        end
      end
    end
  end
end