class PagesController < ApplicationController

  caches_page :splash

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

  def splash
    @title = 'Welcome to Limelight!'
    @description = "The Limelight splash page, where users are directed to sign in"
    @show = params[:show] ? params[:show].to_sym : false
    @topics = Topic.where(:health_index.gte => 2).order_by([[:score, :desc]]).limit(450).to_a
    @topics.shuffle!

    render :layout => false
  end
end
