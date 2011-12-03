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
    @site_style = 'narrow'
    @marc = User.find(User.marc_id)
    @matt = User.find(User.matt_id)
  end

  def contact
    @site_style = 'narrow'
    @feedback_topic = Topic.find(Topic.limelight_feedback_id)
  end

  def privacy
    @site_style = 'narrow'
  end

  def terms
    @site_style = 'narrow'
  end

  def help
    @site_style = 'narrow'
    @feedback_topic = Topic.find(Topic.limelight_feedback_id)
  end
end
