#class TopicConSugsController < ApplicationController
#  before_filter :authenticate_user!
#
#  def new
#    @title = 'Moderate Topic Connections'
#    @description = 'Users can suggest connections between topics, and vote on connections that have already been suggested'
#
#    @site_style = 'narrow'
#    @topic1 = params[:topic_id] ? Topic.find_by_encoded_id(params[:topic_id]) : nil
#    @connections = TopicConnection.all
#  end
#
#  def list
#    if params[:topic1_id].blank? && params[:topic2_id].blank?
#      sugs = []
#    elsif params[:topic2_id].blank?
#      sugs = TopicConSug.any_of({topic1_id: BSON::ObjectId(params[:topic1_id])}, {topic2_id: BSON::ObjectId(params[:topic1_id])})
#    elsif params[:topic1_id].blank?
#      sugs = TopicConSug.any_of({topic1_id: BSON::ObjectId(params[:topic2_id])}, {topic2_id: BSON::ObjectId(params[:topic2_id])})
#    else
#      sugs = TopicConSug.any_of({topic1_id: BSON::ObjectId(params[:topic1_id]), topic2_id: BSON::ObjectId(params[:topic2_id])},
#                                {topic2_id: BSON::ObjectId(params[:topic1_id]), topic1_id: BSON::ObjectId(params[:topic2_id])})
#    end
#
#    list = render_to_string :partial => "list", :locals => { :sugs => sugs }
#    response = build_ajax_response(:ok, nil, nil, nil, {:list => list})
#    status = 200
#    render json: response, status: status
#  end
#end