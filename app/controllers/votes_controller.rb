class VotesController < ApplicationController
  before_filter :authenticate_user!

  #TODO: This will be stuff you've voted on
  def index

  end

  def create
    object = CoreObject.find(params[:id])
    amount = params[:a].to_i

    if object && [1,0,-1].include?(amount)
      if object.user_id == current_user.id
        response = {:json => {:status => 'error', :flash => {:type => 'error', :message => 'You cannot vote on your own posts!'}}, :status => 201}
      else
        object.add_voter(current_user, amount)
        current_user.save if object.save
        response = {:json => {:status => 'ok', :target => '.v_'+object.id.to_s, :toggle_classes => ['voteB', 'unvoteB'], :event => 'voted', :a => amount}, :status => 201}
      end
    else
      response = {:json => {:status => 'error', :message => 'Target object not found!'}, :status => 404}
    end

    respond_to do |format|
      format.json { render response }
    end
  end

  def destroy
    object = CoreObject.find(params[:id])
    if object
      if object.user_id == current_user.id
        response = {:json => {:status => 'error', :flash => {:type => 'error', :message => 'You cannot vote on your own posts!'}}, :status => 201}
      else
        object.remove_voter(current_user)
        current_user.save if object.save
        response = {:json => {:status => 'ok', :target => '.v_'+object.id.to_s, :toggle_classes => ['voteB', 'unvoteB'], :event => 'voted', :a => 0}, :status => 200}
      end
    else
      response = {:json => {:status => 'error', :message => 'Target object not found!'}, :status => 404}
    end

    respond_to do |format|
      format.json { render response }
    end
  end
end
