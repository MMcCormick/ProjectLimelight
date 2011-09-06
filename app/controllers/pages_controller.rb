class PagesController < ApplicationController

  def home
    @title = 'Home'
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {})

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @core_objects }
    end
  end

end
