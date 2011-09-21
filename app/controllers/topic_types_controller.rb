class TopicTypesController < ApplicationController
  before_filter :authenticate_user!

  def new
    @topic_id = params[:topic_id]
    @types = TopicType.all
    @type = TopicType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @types }
    end
  end

  def create
    topic = Topic.find_by_encoded_id(params[:topic_type][:topic_id])
    if params[:topic_type][:id] == ''
      type = current_user.topic_types.build(params[:topic_type])
    else
      type = TopicType.find(params[:topic_type][:id])
    end
    type.topic_count += 1

    if type && type.save
      snippet = topic.topic_type_snippets.build(type.attributes)
      snippet.id = type.id
      snippet.user_id = current_user.id
      topic.save
      response = { :event => 'edit_topic_type',
                   :flash => { :type => :success, :message => 'Topic Type successfully created!' } }
    else
      response = { :event => 'edit_topic_type',
                   :flash => { :type => :error, :message => 'Topic Creation failed.' } }
    end
    render json: response
  end
end