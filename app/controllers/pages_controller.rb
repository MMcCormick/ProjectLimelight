class PagesController < ApplicationController

  def home
    @title = 'Home'
    @core_objects = CoreObject.any_in("_type" => session[:feed_filters][:display])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @core_objects }
    end
  end

end
