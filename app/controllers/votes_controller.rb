class VotesController < ApplicationController
  before_filter :authenticate_user!

  #TODO: This will be stuff you've voted on
  def index

  end

  def create
    if ['Talk', 'News', 'Video', 'Picture', 'Comment'].include? params[:type]
      object = Kernel.const_get(params[:type]).find(params[:id])
      amount = params[:a].to_i

      if object && [1,0,-1].include?(amount)
        if object.user_id == current_user.id
          response = build_ajax_response(:error, nil, 'You cannot vote on your own posts!')
          status = 401
        else
          net = object.add_voter(current_user, amount)
          object.add_pop_vote(:add, net, current_user)
          object.save
          current_user.save
          response = build_ajax_response(:ok, nil, nil, nil, { :target => '.v_'+object.id.to_s, :a => amount})
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
    if ['Talk', 'News', 'Video', 'Picture', 'Comment'].include? params[:type]
      object = Kernel.const_get(params[:type]).find(params[:id])

      if object
        if object.user_id == current_user.id
          response = build_ajax_response(:error, nil, 'You cannot vote on your own posts!')
          status = 401
        else
          net = object.remove_voter(current_user)
          object.add_pop_vote(:remove, net, current_user)
          current_user.save if object.save
          response = build_ajax_response(:ok, nil, nil, nil, { :target => '.v_'+object.id.to_s, :a => 0})
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
