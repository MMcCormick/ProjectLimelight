class EmbedlyController < ApplicationController
  include VideosHelper
  include ImageHelper
  include ApplicationHelper
  include EmbedlyHelper

  def show
    render :json => fetch_url(params[:url])
  end

end