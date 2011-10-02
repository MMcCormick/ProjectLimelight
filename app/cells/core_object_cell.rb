class CoreObjectCell < Cell::Rails

  include Devise::Controllers::Helpers
  helper ImageHelper

  def response
    @object = CoreObject.find(@opts[:id])
    @current_user = current_user

    render
  end

end
