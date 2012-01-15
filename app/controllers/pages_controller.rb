class PagesController < ApplicationController

  def home
    @title = 'Home'
    @description = "The Limelight home page. This is a feed of all posts submitted to the site, which can be customized" +
        "by filtering, sorting, and changing the feed style."
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

  def splash
    @title = 'Welcome to Limelight!'
    @description = "The Limelight splash page, where users are directed to sign in"
    @show = params[:show] ? params[:show].to_sym : false

    render :layout => "blank"
  end

  def admin
    authorize! :manage, :all
    @title = 'Admin'
    @site_style = 'narrow'
  end

  def about
    @title = 'About'
    @description = "A short description of Limelight, a new way to discuss the topics you care about."
    @site_style = 'narrow'
    @marc = User.find(User.marc_id)
    @matt = User.find(User.matt_id)
  end

  def contact
    @title = 'Contact'
    @description = "Contact information for the Limelight Team"
    @site_style = 'narrow'
    @feedback_topic = Topic.find(Topic.limelight_feedback_id)
  end

  def privacy
    @title = 'Privacy'
    @description = "Limelight's Privacy Policy"
    @site_style = 'narrow'
  end

  def terms
    @title = 'Terms'
    @description = "Limelight's Terms of Use"
    @site_style = 'narrow'
  end

  def help
    @title = 'Help'
    @description = "Main help page for Limelight"
    @site_style = 'narrow'
    @feedback_topic = Topic.find(Topic.limelight_feedback_id)
  end
end
