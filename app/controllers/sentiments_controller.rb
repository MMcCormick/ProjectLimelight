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
      indexes = {
              'User' => 'users',
              'UserSnippet' => 'users',
              'Topic' => 'topics',
              'TopicSnippet' => 'topics'
      }
      target = Kernel.const_get(targets[params[:type]]).find_by_encoded_id(params[:id])

      if target && ['positive', 'negative', 'neutral'].include?(params[:sentiment])
        Neo4j.update_sentiment(current_user.id.to_s, 'users', target.id.to_s, indexes[params[:type]], params[:sentiment])

        message = case params[:sentiment]
          when 'positive'
            "Got it, you like #{target.name}."
          when 'negative'
            "Got it, you don't like #{target.name}."
          when 'neutral'
            "Got it, you don't care about #{target.name}."
        end

        if targets[params[:type]] == 'Topic' && params[:sentiment] == 'positive'
          current_user.follow_object(target)
          current_user.save
        end

        response = build_ajax_response(:ok, nil, message, nil)
      else
        response = build_ajax_response(:error, nil, "Hmm... we couldn't find that #{params[:type]}. If this error continues, please contact us!", nil)
      end
    else
      response = build_ajax_response(:error, nil, 'Limelight does not support opinions on that type of object!', nil)
    end

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end

end