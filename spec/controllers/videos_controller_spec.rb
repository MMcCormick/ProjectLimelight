require 'spec_helper'

describe VideosController do
  describe "GET show" do
    context "when video is found" do
      let(:video) { mock('video') }
      before(:each) do
        Video.should_receive(:find_by_encoded_id).with('1').and_return(video)
        get :show, :id => 1
      end

      it "should assign the video variable" do
        assigns[:video].should eq(video)
      end
      it "should respond with success" do
        response.should be_success
      end
      it "should render the show template" do
        response.should render_template "show"
      end
    end

    it "should raise a 404 if the video is not found" do
      Video.should_receive(:find_by_encoded_id).and_return(false)
      get :show, :id => 2
      response.response_code.should == 404
    end
  end

  describe "POST create" do
    context "when not signed in" do
      it "should not assign video" do
        post :create
        assigns[:video].should be_nil
      end
      it "should respond with a 401" do
        post :create
        response.response_code.should == 401
      end
    end

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      let(:video) { mock_model(Video).as_null_object }
      before(:each) do
        sign_in user
        Video.should_receive(:new).with({"content" => "blah blah"}, {}).and_return(video)
      end

      it "should create a new video" do
        post :create, :video => {"content" => "blah blah"}
        assigns[:video].should eq(video)
      end
      it "should save the new video" do
        video.should_receive(:save)
        post :create, :video => {"content" => "blah blah"}
      end

      context "on success" do
        before(:each) { video.should_receive(:save).and_return(true) }

        it "should redirect to the video show page" do
          post :create, :video => {"content" => "blah blah"}
          response.should redirect_to video
        end
        it "should redirect to the video show page (json)" do
          post :create, :video => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 201
          JSON.parse(response.body)['redirect'].should == video_path(video)
          JSON.parse(response.body)['status'].should == "ok"
        end
      end

      context "on failure" do
        before(:each) { video.should_receive(:save).and_return(false) }

        it "should redirect to new video path" do
          post :create, :video => {"content" => "blah blah"}
          response.should render_template("new")
        end
        it "should return a json object with a 422 code (json)" do
          post :create, :video => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 422
          JSON.parse(response.body)['status'].should == "error"
        end
      end
    end
  end
end