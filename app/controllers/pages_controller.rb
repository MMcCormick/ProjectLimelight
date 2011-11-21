class PagesController < ApplicationController

  def home
    @title = 'Home'
    page = params[:p] ? params[:p].to_i : 1
    @more_path = root_path :p => page + 1
    @core_objects = CoreObject.feed(session[:feed_filters][:display], session[:feed_filters][:sort], {:page => page})

    respond_to do |format|
      format.js {
        response = reload_feed(@core_objects, @more_path, page)
        render json: response
      }
      format.html
    end
  end

  def about

  end

  def contact
    @feedback_topic = Topic.find(Topic.limelight_feedback_id)
  end

  def privacy

  end

  def terms

  end

  def help

  end
end
