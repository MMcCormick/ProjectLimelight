class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]

  def show
    @user = User.find_by_slug(params[:id])
  end

end
