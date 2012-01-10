class VotesController < ApplicationController
  before_filter :authenticate_user!

  #TODO: This will be stuff you've voted on
  def index

  end

  def create
    if ['Talk', 'Link', 'Video', 'Picture', 'Comment', 'TopicConSug'].include? params[:type]
      object = Kernel.const_get(params[:type]).find(params[:id])
      amount = params[:a].to_i

      if object && [1,0,-1].include?(amount)
        if object.user_id == current_user.id
          response = build_ajax_response(:error, nil, 'You cannot vote on your own posts!')
          status = 401
        else
          net = object.add_voter(current_user, amount)
          object.add_pop_vote(:a, net, current_user) if net && params[:type] != 'TopicConSug'
          object.save!
          current_user.save!
          ActionVote.create(
                  :action => 'create',
                  :from_id => current_user.id,
                  :to_id => object.id,
                  :to_type => object.class.name,
                  :amount => amount
          )
          if ['Talk', 'Link', 'Video', 'Picture'].include? params[:type]
            if amount < 0
              sentiment = 'negative'
            elsif amount == 0
              sentiment = 'neutral'
            else
              sentiment = 'positive'
            end
            Neo4j.update_sentiment(current_user.id.to_s, 'users', object.id.to_s, 'posts', sentiment)
          end

          response = build_ajax_response(:ok, nil, nil, nil, { :id => object.id.to_s, :a => amount })
          status = 201
        end
      else
        response = build_ajax_response(:error, nil, 'Target object not found!', nil)
        status = 404
      end
    else
      response = build_ajax_response(:error, nil, 'Invalid object type')
      status = 400
    end

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end

  def destroy
    if ['Talk', 'Link', 'Video', 'Picture', 'Comment', 'TopicConSug'].include? params[:type]
      object = Kernel.const_get(params[:type]).find(params[:id])

      if object
        if object.user_id == current_user.id
          response = build_ajax_response(:error, nil, 'You cannot vote on your own posts!')
          status = 401
        else
          net = object.remove_voter(current_user)
          object.add_pop_vote(:r, net, current_user) if params[:type] != 'TopicConSug'
          current_user.save!
          object.save!
          if ['Talk', 'Link', 'Video', 'Picture'].include? params[:type]
            Neo4j.update_sentiment(current_user.id.to_s, 'users', object.id.to_s, 'posts', 'neutral')
          end
          response = build_ajax_response(:ok, nil, nil, nil, { :id => object.id.to_s, :a => 0 })
          status = 200
        end
      else
        response = build_ajax_response(:error, nil, 'Target object not found!', nil)
        status = 404
      end
    else
      response = build_ajax_response(:error, nil, 'Invalid object type')
      status = 400
    end

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end
end
