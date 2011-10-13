require 'spec_helper'

describe FavoritesController do
  describe "GET index" do
    context "when not signed in" do
      it "should redirect to root when not signed in" do
        get :index, :id => "foobar"
        response.should redirect_to(root_path)
      end
    end

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      before(:each) { sign_in user }

      it "should raise a 404 if the user is not found" do
        User.should_receive(:find_by_slug).with("foobar").and_return(nil)
        get :index, :id => "foobar"
        response.response_code.should == 404
      end

      it "should set the user, more_path, and core_objects variables" do
        talk = mock('talk')
        User.should_receive(:find_by_slug).and_return(user)
        CoreObject.should_receive(:feed).and_return(talk)
        get :index, :id => "foobar", :p => "2"
        assigns[:user].should eq(user)
        assigns[:more_path].should == (user_favorites_path :p => 3)
        assigns[:core_objects].should == talk
      end

      it "should respond appropriately to different types of requests"
    end
  end

  describe "POST create" do
    it "should respond with a 404 if the object is not found"
  end
end