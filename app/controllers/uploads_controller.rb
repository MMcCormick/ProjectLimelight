class UploadsController < ApplicationController
  def create
    name = "#{Digest::MD5.hexdigest(current_user.email.downcase)}-#{params[:file].original_filename}"
    directory = "#{Rails.root}/public/uploads"
    Dir.mkdirs(directory) unless File.directory?(directory)
    directory = "#{Rails.root}/public/uploads/tmp"
    Dir.mkdirs(directory) unless File.directory?(directory)
    path = File.join(directory, name)
    File.open(path, "wb") { |f| f.write(params[:file].read) }

    render :json => {:image_location => name, :image_path => path}
  end
end