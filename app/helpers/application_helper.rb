module ApplicationHelper

  # Return a title on a per-page basis.
  def title
    base_title = "Limelight"
    if @title.nil?
      base_title
    else
      "#{base_title} | #{@title}"
    end
  end

  # Devise helper
  # https://github.com/plataformatec/devise/wiki/How-To:-Display-a-custom-sign_in-form-anywhere-in-your-app
  def resource_name
    :user
  end

  # Devise helper
  def resource
    @resource ||= User.new
  end

  # Devise helper
  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

end
