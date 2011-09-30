class PagesController < ApplicationController

  def home
    @title = 'Home'
    page = params[:p] ? params[:p].to_i : 1
    @more_path = root_path :p => page + 1
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {:page => page})

    respond_to do |format|
      if request.xhr?
        html =  render_to_string :partial => "core_objects/feed", :locals => { :more_path => @more_path }
        format.json { render json: { :event => "loaded_feed_page", :content => html } }
      else
        format.html # index.html.erb
        format.json { render json: @core_objects }
      end
    end
  end

end
