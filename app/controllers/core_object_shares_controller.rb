class CoreObjectSharesController < ApplicationController
  before_filter :authenticate_user!

  def create
    receiver_slugs = params[:core_object_share][:receiver_slugs].split(',').map! { |elem| elem.strip }
    receiver_slugs.delete(current_user.slug)
    receivers = User.where(:slug.in => receiver_slugs)
    object = CoreObject.find(params[:core_object_share][:core_object_id])

    if !receivers.empty? and object
      # Searches for a core object share from the current user of the same object
      core_object_share = CoreObjectShare.where(:user_id => current_user.id, :core_object_id => BSON::ObjectId(object.id.to_s)).first
      # If none is found, make a new share and set appropriate vars
      if core_object_share.nil?
        core_object_share = current_user.core_object_shares.build(params[:core_object_share])
        core_object_share.set_sender_snippet(current_user)
        core_object_share.set_shared_object_snippet(object)
        core_object_share.grant_owner(current_user.id)
      end
      # Update the receivers
      core_object_share.set_receiver_snippets(receivers)
      core_object_share.save!
      response = { :event => 'core_object_share_created',
                   :flash => { :type => :success, :message => 'Share successful!' } }
    else
      response = { :event => 'core_object_share_created',
                   :flash => { :type => :error, :message => 'Item could not be shared' } }
    end

    render json: response
  end

end
