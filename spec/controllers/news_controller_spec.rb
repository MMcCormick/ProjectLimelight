require 'spec_helper'

describe NewsController do
  describe "GET show" do
    context "when html request" do
      context "and news is found" do
        let(:news) { mock('news') }
        before(:each) do
          News.should_receive(:find_by_encoded_id).with('1').and_return(news)
          get :show, :id => 1
        end

        it "should assign the news variable" do
          assigns[:news].should eq(news)
        end
        it "should respond with success" do
          response.should be_success
        end
        it "should render the show template" do
          response.should render_template "show"
        end
      end

      it "should raise a 404 if the news is not found" do
        News.should_receive(:find_by_encoded_id).and_return(false)
        get :show, :id => 2
        response.response_code.should == 404
      end
    end

    context "when json request" do
      context "and news is found" do
        let(:news) { FactoryGirl.create(:news) }
        before(:each ) do
          News.should_receive(:find_by_encoded_id).with('1').and_return(news)
          get :show, :id => 1, :format => :json
        end
        it "should respond with success" do
          response.should be_success
        end
        it "should respond with a json object where the id matches the news id" do
          JSON.parse(response.body)['_id'].should == news.id.to_s
        end
      end
      it "should respond with a 404 status if the news is not found" do
        News.should_receive(:find_by_encoded_id).and_return(false)
        get :show, :id => 2, :format => :json
        response.response_code.should == 404
      end
    end
  end

  describe "POST create" do
    context "when not signed in" do
      it "should not assign news" do
        post :create
        assigns[:news].should be_nil
      end
      it "should respond with a 401" do
        post :create
        response.response_code.should == 401
      end
    end

    context "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      let(:news) { mock_model(News).as_null_object }
      before(:each) do
        sign_in user
        News.should_receive(:new).with("content" => "blah blah").and_return(news)
      end

      it "should create a new news" do
        post :create, :news => {"content" => "blah blah"}
        assigns[:news].should eq(news)
      end
      it "should save the new news" do
        news.should_receive(:save)
        post :create, :news => {"content" => "blah blah"}
      end

      context "on success" do
        before(:each) { news.should_receive(:save).and_return(true) }

        it "should redirect to the news show page" do
          post :create, :news => {"content" => "blah blah"}
          response.should redirect_to news
        end
        it "should redirect to the news show page (json)" do
          post :create, :news => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 201
          JSON.parse(response.body)['redirect'].should == news_path(news)
        end
      end

      context "on failure" do
        before(:each) { news.should_receive(:save).and_return(false) }

        it "should redirect to new news path" do
          post :create, :news => {"content" => "blah blah"}
          response.should render_template("new")
        end
        it "should return a json object with a 422 code (json)" do
          post :create, :news => {"content" => "blah blah"}, :format => :json
          response.response_code.should == 422
        end
      end
    end
  end
end