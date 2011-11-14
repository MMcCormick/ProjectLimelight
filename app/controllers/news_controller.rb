class NewsController < ApplicationController
  authorize_resource

  def show
    @news = News.find_by_encoded_id(params[:id])
    @responses = CoreObject.feed([:Talk], {'target' => 'created_at', 'order' => 'ASC'}, {:limit => 500, :response_to_id => @news.id})
    unless @news
      not_found("Talk not found")
    end
  end

  def create
    @news = current_user.news.build(params[:news])
    @news.save_original_image
    @news.save_images

    if @news.save
      @news.send_mention_notifications
      response = build_ajax_response(:ok, news_path(@news), "News was successfully created")
      render json: response, status: :created
    else
      response = build_ajax_response(:error, nil, "News could not be created", @news.errors)
      render json: response, status: :unprocessable_entity
    end
  end

end
