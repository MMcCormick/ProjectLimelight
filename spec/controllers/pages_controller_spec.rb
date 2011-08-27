require 'spec_helper'

describe PagesController do
  render_views

  before(:each) do
  end

  describe "GET 'home'" do
    it "assigns all core_objects as @core_objects" do
      core_objects = CoreObject.all
      get :home
      assigns(:core_objects).should eq(core_objects)
    end

    #it "should have the right title" do
    #  get 'home'
    #  response.should have_selector("title", :content => "Home")
    #end
  end

end
