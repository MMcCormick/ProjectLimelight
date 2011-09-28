class NewsController < ApplicationController
  before_filter :authenticate_user!, :except => [:show]

  def show
    @news = News.find_by_encoded_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @news }
    end
  end

  def create
    @news = current_user.news.build(params[:news])
    if @news.valid?
      # TODO: Factor this out of the controller
      # Create/attach the news image
      image_snippet = ImageSnippet.new
      image_snippet.user_id = current_user.id
      image_snippet.add_uploaded_version(params[:news][:asset_image], true)
      @news.images << image_snippet
      # We must explicitly save the images so that CarrierWave stores them
      @news.save_images
    end

    respond_to do |format|
      if @news.save
        response = { :redirect => news_path(@news) }
        format.html { redirect_to @news, notice: 'News was successfully created.' }
        format.json { render json: response, status: :created, location: @news }
      else
        format.html { render action: "new" }
        format.json { render json: @news.errors, status: :unprocessable_entity }
      end
    end
  end

end
