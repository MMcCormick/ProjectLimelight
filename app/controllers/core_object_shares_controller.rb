class CoreObjectSharesController < ApplicationController

  def create
    receiver_slugs = params[:core_object_share][:receiver_slugs].split(%r{,\s*}).map! { |elem| elem.strip }
    receiver_slugs.delete(current_user.slug)
    receivers = User.where(:slug.in => receiver_slugs)
    object = CoreObject.find(params[:core_object_share][:core_object_id])

    if receivers.empty?
      response = build_ajax_response(:error, talk_path(@talk), "That user could not be found!")
      status = :unprocessable_entity
    elsif !object
      response = build_ajax_response(:error, talk_path(@talk), "The post could not be shared")
      status = :unprocessable_entity
    else
      receivers.each do |receiver|
        unless receiver.id == current_user.id || receiver.id == object.user_id
          notification = Notification.where(:user_id => receiver.id, :type => :share, 'object._id' => object.id, 'triggered_by._id' => current_user.id).first
          unless notification
            object.add_pop_action(:share, :a, current_user) if object.user_id != current_user.id
            ShareMailer.share(current_user, receiver, object, object.user).deliver if receiver.shares_email
            Notification.add(receiver, :share, false, current_user, nil, nil, true, object, object.user)
          end
        end
      end
      object.save!

      response = build_ajax_response(:ok, nil, "#{object.class.name.downcase} successfully shared with #{receivers.length} user#{'s' if receivers.length > 1}!")
      status = :created
    end

    render json: response, status: status
  end

end
