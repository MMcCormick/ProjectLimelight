class NewsController < ApplicationController
  authorize_resource

  def show
    @news = News.find_by_encoded_id(params[:id])
    respond_to do |format|
      if @news
        format.html # show.html.erb
        format.json { render json: @news }
      else
        not_found("News not found")
      end
    end
  end

  def create
    @news = current_user.news.build(params[:news])
    @news.save_original_image
    @news.save_images

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
