require 'spec_helper'

describe TalksController, :focus => true do
  #include Devise::TestHelpers
  #render_views

  describe "GET show" do
    it "should respond with success for valid object" do
      pending "convert mocha to rspec"
      talk = mock('foo_talk')
      Talk.expects(:find_by_encoded_id).with('1').returns(talk)
      get :show, :id => 1
      response.should be_success
      assigns[:talk].should eq(talk)
    end
  end

  describe "POST create" do
    context "when not signed in" do
      it "should redirect to the sign in page"
    end

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      let(:talk) { mock_model(Talk) }
      before(:each) do
        sign_in user
      end

      it "should create a new talk" do
        Talk.expects(:new).with("content" => "blah blah").returns(talk)
        post :create, :talk => {"content" => "blah blah"}
        assigns[:talk].should eq(talk)
      end
      it "should save the new talk" do
        talk.expects(:save)
        post :create, :talk => {"content" => "blah blah"}
      end
      #it "should redirect to the talk show page on success" do
      #  post :create
      #  Talk.stub(:new)
      #  response.should redirect_to(:action => 'show')
      #end
      #it "should redirect to home on failure"
    end
  end
end