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

      context "with mock talk" do
        let(:talk) { mock('talk') }
        before(:each) do
          User.should_receive(:find_by_slug).with("foobar").and_return(user)
          Post.should_receive(:feed).and_return(talk)
        end

        it "should set the user, more_path, and core_objects variables" do
          get :index, :id => "foobar", :p => "2"
          assigns[:user].should eq(user)
          assigns[:more_path].should == (user_favorites_path :p => 3)
          assigns[:core_objects].should == talk
        end
        it "should render index.html on html request" do
          get :index, :id => "foobar", :p => 2
          response.should render_template :index
        end
        it "should respond with a json object w/ loaded_feed_page event on xhr request" do
          xhr :get, :index, :id => "foobar", :p => 2
          JSON.parse(response.body)['event'].should == "loaded_feed_page"
        end
        it "should respond with a json object containing the feed on xhr request"
      end
    end
  end

  describe "POST create" do
    it "should click the login button when not signed in"

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      before(:each) { sign_in user }

      it "should respond with a 404 + json error object if the object is not found" do
        Post.should_receive(:find).with("fooid").and_return(nil)
        xhr :post, :create, :id => "fooid"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 404
      end

      context "when object is found" do
        let(:object) { mock('object').as_null_object }
        before(:each) { Post.should_receive(:find).with("fooid").and_return(object) }

        it "should call add_to_favorites on the object" do
          object.should_receive(:add_to_favorites).with(user)
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
        Post.should_receive(:find).with("fooid").and_return(nil)
        xhr :delete, :destroy, :id => "fooid"
        JSON.parse(response.body)['status'].should == "error"
        response.response_code.should == 404
      end

      context "when object is found" do
        let(:object) { mock('object').as_null_object }
        before(:each) { Post.should_receive(:find).with("fooid").and_return(object) }

        it "should call remove_from_favorites on the object" do
          object.should_receive(:remove_from_favorites).with(user)
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