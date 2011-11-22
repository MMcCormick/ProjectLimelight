class NewsController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]

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
      extras = { :type => "News", :path => news_path(@news), :response => !!@news.response_to }
      response = build_ajax_response(:ok, nil, nil, nil, extras)
      render json: response, status: :created
    else
      response = build_ajax_response(:error, nil, "News could not be created", @news.errors)
      render json: response, status: :unprocessable_entity
    end
  end

end
