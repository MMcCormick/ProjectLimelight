class RegistrationsController < Devise::RegistrationsController

  # POST /resource
  def create
    build_resource

    if resource.save
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        render json: build_ajax_response(:ok, after_sign_up_path_for(resource)), status: 201
      else
        set_flash_message :notice, :inactive_signed_up, :reason => inactive_reason(resource) if is_navigational_format?
        expire_session_data_after_sign_in!
        render json: build_ajax_response(:ok, after_inactive_sign_up_path_for(resource)), status: 201
      end
    else
      clean_up_passwords(resource)
      if resource.errors[:invite_code_id].blank?
        render json: build_ajax_response(:error, nil, nil, resource.errors), status: 422
      else
        flash[:register_fail] = "Your invite code is invalid!"
        render json: build_ajax_response(:error, splash_path, nil), status: 422
      end
    end
  end
end
