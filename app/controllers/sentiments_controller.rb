class SentimentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    if ['User', 'UserSnippet', 'Topic', 'TopicSnippet'].include? params[:type]
      targets = {
              'User' => 'User',
              'UserSnippet' => 'User',
              'Topic' => 'Topic',
              'TopicSnippet' => 'Topic'
      }
      target = Kernel.const_get(targets[params[:type]]).find(params[:id])

      if target
        old_sentiment = Neo4j.get_sentiment(current_user.id.to_s, target.id.to_s)
        target.remove_sentiment(old_sentiment) if old_sentiment

        target.add_sentiment(params[:sentiment]) if params[:sentiment]

        Neo4j.toggle_sentiment('users', current_user.id.to_s, params[:type].downcase.pluralize, target.id.to_s, params[:direction], params[:sentiment])
        target.save

        response = build_ajax_response(:ok, nil, nil, nil)
        render :json => response, :status => 200
      end
    end
  end

end