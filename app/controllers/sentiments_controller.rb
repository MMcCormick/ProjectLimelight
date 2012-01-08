class SentimentsController < ApplicationController

  def create
    if ['User', 'UserSnippet', 'Topic', 'TopicSnippet'].include? params[:type]
      targets = {
              'User' => 'User',
              'UserSnippet' => 'User',
              'Topic' => 'Topic',
              'TopicSnippet' => 'Topic'
      }
      indexes = {
              'User' => 'users',
              'UserSnippet' => 'users',
              'Topic' => 'topics',
              'TopicSnippet' => 'topics'
      }
      target = Kernel.const_get(targets[params[:type]]).find(params[:id])

      if target
        Neo4j.update_sentiment(current_user.id.to_s, 'users', target.id.to_s, indexes[params[:type]], params[:sentiment])

        response = build_ajax_response(:ok, nil, nil, nil)
      else
        response = build_ajax_response(:error, nil, nil, nil)
      end
    else
      response = build_ajax_response(:error, nil, nil, nil)
    end
    render :json => response, :status => 200
  end

end