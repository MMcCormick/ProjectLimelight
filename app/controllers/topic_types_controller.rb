class TopicTypesController < ApplicationController
  before_filter :authenticate_user!

  def create
    topic = Topic.find_by_encoded_id(params[:topic_type][:topic_id])

    if !has_permission?(current_user, topic, "edit")
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
        type.topic_count += 1

        if type && type.save
          snippet = topic.topic_type_snippets.build(type.attributes)
          snippet.id = type.id
          snippet.user_id = current_user.id
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
    topic = Topic.find_by_encoded_id(params[:topic_id])
    if !has_permission?(current_user, topic, "edit")
      response = { :event => 'edit_topic_type', :flash => { :type => :error, :message => 'You are not allowed to add topic types!' } }
    else
      if topic.topic_type_snippets.find(params[:type_id]).destroy
        type = TopicType.find(params[:type_id])
        type.topic_count -= 1
        response = { :flash => { :type => :success, :message => 'Topic Type removed!' } }
      else
        response = { :flash => { :type => :error, :message => 'Topic Type could not be removed' } }
      end
    end
    render json: response
  end
end