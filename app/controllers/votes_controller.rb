class VotesController < ApplicationController
  authorize_resource

  #TODO: This will be stuff you've voted on
  def index

  end

  def create
    object = CoreObject.find(params[:id])
    amount = params[:a].to_i

    if object && [1,0,-1].include?(amount)
      object.add_voter(current_user, amount)
      current_user.save if object.save
      response = {:json => {:status => 'ok', :target => '.v_'+object.id.to_s, :toggle_classes => ['voteB', 'unvoteB']}, :event => 'voted_created', :status => 201}
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
      object.remove_voter(current_user)
      current_user.save if object.save
      response = {:json => {:status => 'ok', :target => '.v_'+object.id.to_s, :toggle_classes => ['voteB', 'unvoteB']}, :event => 'voted_destroyed', :status => 200}
    else
      response = {:json => {:status => 'error', :message => 'Target object not found!'}, :status => 404}
    end

    respond_to do |format|
      format.json { render response }
    end
  end
end
