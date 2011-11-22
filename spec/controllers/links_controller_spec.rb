require 'spec_helper'

describe LinksController do
  describe "GET show" do
    context "when links is found" do
      let(:links) { mock('links') }
      before(:each) do
        Link.should_receive(:find_by_encoded_id).with('1').and_return(link)
        get :show, :id => 1
      end

      it "should assign the links variable" do
        assigns[:links].should eq(link)
      end
      it "should respond with success" do
        response.should be_success
      end
      it "should render the show template" do
        response.should render_template "show"
      end
    end

    it "should raise a 404 if the links is not found" do
      Link.should_receive(:find_by_encoded_id).and_return(false)
      get :show, :id => 2
      response.response_code.should == 404
    end
  end

  describe "POST create" do
    context "when not signed in" do
      it "should not assign links" do
        post :create
        assigns[:links].should be_nil
      end
      it "should respond with a 401" do
        post :create
        response.response_code.should == 401
      end
    end

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      let(:links) { mock_model(Link).as_null_object }
      before(:each) do
        sign_in user
        Link.should_receive(:new).with({"content" => "blah blah"}, {}).and_return(link)
      end

      it "should create a new links" do
        post :create, :links => {"content" => "blah blah"}
        assigns[:links].should eq(link)
      end
      it "should save the new links" do
        link.should_receive(:save)
        post :create, :links => {"content" => "blah blah"}
      end

      context "on success" do
        before(:each) { link.should_receive(:save).and_return(true) }

        it "should redirect to the links show page" do
          post :create, :links => {"content" => "blah blah"}
          response.should redirect_to link
        end
        it "should redirect to the links show page (json)" do
          post :create, :links => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 201
          JSON.parse(response.body)['redirect'].should == link_path(link)
          JSON.parse(response.body)['status'].should == "ok"
        end
      end

      context "on failure" do
        before(:each) { link.should_receive(:save).and_return(false) }

        it "should redirect to new links path" do
          post :create, :links => {"content" => "blah blah"}
          response.should render_template("new")
        end
        it "should return a json object with a 422 code (json)" do
          post :create, :links => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 422
          JSON.parse(response.body)['status'].should == "error"
        end
      end
    end
  end
end