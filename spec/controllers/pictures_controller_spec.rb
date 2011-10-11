require 'spec_helper'

describe PicturesController do
  describe "GET show" do
    context "when html request" do
      context "and picture is found" do
        let(:picture) { mock('picture') }
        before(:each) do
          Picture.should_receive(:find_by_encoded_id).with('1').and_return(picture)
          get :show, :id => 1
        end

        it "should assign the picture variable" do
          assigns[:picture].should eq(picture)
        end
        it "should respond with success" do
          response.should be_success
        end
        it "should render the show template" do
          response.should render_template "show"
        end
      end

      it "should raise a 404 if the picture is not found" do
        Picture.should_receive(:find_by_encoded_id).and_return(false)
        get :show, :id => 2
        response.response_code.should == 404
      end
    end

    context "when json request" do
      context "and picture is found" do
        let(:picture) { FactoryGirl.create(:picture) }
        before(:each ) do
          Picture.should_receive(:find_by_encoded_id).with('1').and_return(picture)
          get :show, :id => 1, :format => :json
        end
        it "should respond with success" do
          response.should be_success
        end
        it "should respond with a json object where the id matches the picture id" do
          JSON.parse(response.body)['_id'].should == picture.id.to_s
        end
      end
      it "should respond with a 404 status if the picture is not found" do
        Picture.should_receive(:find_by_encoded_id).and_return(false)
        get :show, :id => 2, :format => :json
        response.response_code.should == 404
      end
    end
  end

  describe "POST create" do
    context "when not signed in" do
      it "should not assign picture" do
        post :create
        assigns[:picture].should be_nil
      end
      it "should respond with a 401" do
        post :create
        response.response_code.should == 401
      end
    end

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      let(:picture) { mock_model(Picture).as_null_object }
      before(:each) do
        sign_in user
        Picture.should_receive(:new).with("content" => "blah blah").and_return(picture)
      end

      it "should create a new picture" do
        post :create, :picture => {"content" => "blah blah"}
        assigns[:picture].should eq(picture)
      end
      it "should save the new picture" do
        picture.should_receive(:save)
        post :create, :picture => {"content" => "blah blah"}
      end

      context "on success" do
        before(:each) { picture.should_receive(:save).and_return(true) }

        it "should redirect to the picture show page" do
          post :create, :picture => {"content" => "blah blah"}
          response.should redirect_to picture
        end
        it "should redirect to the picture show page (json)" do
          post :create, :picture => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 201
          JSON.parse(response.body)['redirect'].should == picture_path(picture)
        end
      end

      context "on failure" do
        before(:each) { picture.should_receive(:save).and_return(false) }

        it "should redirect to new picture path" do
          post :create, :picture => {"content" => "blah blah"}
          response.should render_template("new")
        end
        it "should return a json object with a 422 code (json)" do
          post :create, :picture => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 422
        end
      end
    end
  end
end