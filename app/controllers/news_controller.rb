class NewsController < ApplicationController
  authorize_resource

  def show
    @news = News.find_by_encoded_id(params[:id])
    unless @news
      not_found("Talk not found")
    end
  end

  def create
    @news = current_user.news.build(params[:news])
    @news.save_original_image
    @news.save_images

    respond_to do |format|
      if @news.save
        format.html { redirect_to @news }
        response = build_ajax_response(:ok, news_path(@news), "News was successfully created")
        format.json { render json: response, status: :created }
      else
        format.html { render action: "new" }
        response = build_ajax_response(:error, nil, "News could not be created", @news.errors)
        format.json { render json: response, status: :unprocessable_entity }
      end
    end
  end

end
