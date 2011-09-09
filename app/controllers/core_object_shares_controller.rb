class CoreObjectSharesController < ApplicationController
  before_filter :authenticate_user!

  def index


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @core_core_object_share }
    end
  end

  def create
    receiver_slugs = params[:core_object_share][:receiver_slugs].split(',').map! { |elem| elem.strip }
    receiver_slugs.delete(current_user.slug)
    receivers = User.where(:slug.in => receiver_slugs)
    object = CoreObject.find(params[:core_object_share][:core_object_id])

    if receivers and object
      core_object_share = CoreObjectShare.where(:user_id => current_user.id, :core_object_id => BSON::ObjectId(object.id.to_s)).first
      if core_object_share.nil?
        core_object_share = current_user.core_object_shares.build(params[:core_object_share])
        core_object_share.set_sender_snippet(current_user)
        core_object_share.grant_owner(current_user.id)
      end
      core_object_share.set_receiver_snippets(receivers)
      # TODO: when shared_object_snippet is not set every save, raises validation error (WTF)
      core_object_share.set_shared_object_snippet(object)
    end

    core_object_share.save!
    render json: core_object_share
  end

end
