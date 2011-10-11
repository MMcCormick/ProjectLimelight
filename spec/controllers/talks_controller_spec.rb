require 'spec_helper'

describe TalksController do
  describe "GET show" do
    context "when html request" do
      context "and talk is found" do
        let(:talk) { mock('talk') }
        before(:each) do
          Talk.should_receive(:find_by_encoded_id).with('1').and_return(talk)
          get :show, :id => 1
        end

        it "should assign the talk variable" do
          assigns[:talk].should eq(talk)
        end
        it "should respond with success" do
          response.should be_success
        end
        it "should render the show template" do
          response.should render_template "show"
        end
      end

      it "should raise a 404 if the talk is not found" do
        Talk.should_receive(:find_by_encoded_id).and_return(false)
        get :show, :id => 2
        response.response_code.should == 404
      end
    end

    context "when json request" do
      context "and talk is found" do
        # Note: examples below uses a Factory-made talk object so that the json response can be tested
        # If a mock or mock_model is used, the json object is blank
        let(:talk) { FactoryGirl.create(:talk) }
        before(:each ) do
          Talk.should_receive(:find_by_encoded_id).with('1').and_return(talk)
          #talk = mock_model(Talk).as_null_object
          get :show, :id => 1, :format => :json
        end
        it "should respond with success" do
          response.should be_success
        end
        it "should respond with a json object where the id matches the talk id" do
          JSON.parse(response.body)['_id'].should == talk.id.to_s
        end
      end
      it "should respond with a 404 status if the talk is not found" do
        Talk.should_receive(:find_by_encoded_id).and_return(false)
        get :show, :id => 2, :format => :json
        response.response_code.should == 404
      end
    end
  end

  describe "POST create" do
    context "when not signed in" do
      it "should not assign talk" do
        post :create
        assigns[:talk].should be_nil
      end
      it "should respond with a 401" do
        post :create
        response.response_code.should == 401
      end
    end

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      let(:talk) { mock_model(Talk).as_null_object }
      before(:each) do
        sign_in user
        Talk.should_receive(:new).with("content" => "blah blah").and_return(talk)
      end
      it "should create a new talk" do
        post :create, :talk => {"content" => "blah blah"}
        assigns[:talk].should eq(talk)
      end
      it "should save the new talk" do
        talk.should_receive(:save)
        post :create, :talk => {"content" => "blah blah"}
      end

      context "on success" do
        before(:each) { talk.should_receive(:save).and_return(true) }

        it "should redirect to the talk show page" do
          post :create, :talk => {"content" => "blah blah"}
          response.should redirect_to talk
        end
        it "should redirect to the talk show page (json)" do
          post :create, :talk => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 201
          JSON.parse(response.body)['redirect'].should == talk_path(talk)
        end
      end

      context "on failure" do
        before(:each) { talk.should_receive(:save).and_return(false) }

        it "should redirect to new talk path" do
          post :create, :talk => {"content" => "blah blah"}
          response.should render_template("new")
        end
        it "should return a json object with a 422 code (json)" do
          post :create, :talk => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 422
        end
      end
    end
  end
end