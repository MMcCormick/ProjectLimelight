class UploadsController < ApplicationController
  def create
    name = "#{Digest::MD5.hexdigest(current_user.email.downcase)}-#{params[:file].original_filename}"
    directory = "#{Rails.root}/public/tmp_uploads"
    path = File.join(directory, name)
    File.open(path, "wb") { |f| f.write(params[:file].read) }

    render :json => {:image_location => name, :image_path => path}
  end
end