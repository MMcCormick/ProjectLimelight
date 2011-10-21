class TopicTypesController < ApplicationController
  before_filter :find_topic_type, :only => :destroy
  authorize_resource

  def create
    topic = Topic.find_by_encoded_id(params[:topic_type][:topic_id])

    if cannot? :edit, topic
      response = { :event => 'edit_topic_type', :flash => { :type => :error, :message => 'You are not allowed to add topic types!' } }
    else
      # If the user didn't select an option from the select
      if params[:topic_type][:id].blank?
        type = TopicType.where(slug: params[:topic_type][:name].to_url).first
        unless type
          type = current_user.topic_types.build(params[:topic_type])
        end
      else
        type = TopicType.find(params[:topic_type][:id])
      end

      if topic.topic_type_snippets.where(:name => type.name).exists?
        response = { :event => 'edit_topic_type', :flash => { :type => :error, :message => 'The topic already has that type!' } }
      else

        if type && type.save
          snippet = TopicTypeSnippet.new(type.attributes)
          snippet.id = type.id
          snippet.user_id = current_user.id
          topic.topic_type_snippets << snippet
          topic.save
          response = { :event => 'edit_topic_type', :flash => { :type => :success, :message => 'Topic Type added!' } }
        else
          response = { :event => 'edit_topic_type', :flash => { :type => :error, :message => 'Topic Type could not be added.' } }
        end
      end
    end
    render json: response
  end

  def destroy
    if @topic_type
      @topic_type.destroy
      response = { :flash => { :type => :success, :message => 'Topic Type removed!' } }
    else
      response = { :flash => { :type => :error, :message => 'Topic Type could not be removed' } }
    end

    render json: response
  end

  private

  def find_topic_type
    topic = Topic.find_by_encoded_id(params[:topic_id])
    @topic_type = topic.topic_type_snippets.find(params[:type_id])
  end
end