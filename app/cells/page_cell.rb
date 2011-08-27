class PageCell < Cell::Rails

  include Devise::Controllers::Helpers

  def sidebar_left
    @user = current_user
    render
  end

end
