class UploadsController < ApplicationController
  def create
    hash = "#{Digest::MD5.hexdigest(current_user.email.downcase)}-#{params[:file].original_filename}"
    location = "#{Rails.root}/public/uploads/tmp/#{hash}"
    writeOut = open(location, "wb")
    writeOut.write(params[:file].read)
    writeOut.close

    render :json => {:image_location => hash, :image_path => location}
  end
end