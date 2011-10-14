class CoreObjectCell < Cell::Rails

  include Devise::Controllers::Helpers
  helper ImageHelper

  def response(id)
    @object = CoreObject.find(id)
    @current_user = current_user

    render
  end

end
