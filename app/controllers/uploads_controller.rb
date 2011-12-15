class UploadsController < ApplicationController
  def create
    uploader = ImageUploader.new
    uploader.store!(params[:file])

    if Rails.env.development?
      target_directory = 'http://localhost:3000/uploads/images/'
    elsif Rails.env.staging?
      target_directory = 'http://staging.img.p-li.me/'
    else
      target_directory = 'http://img.p-li.me/'
    end

    render :json => {:image_location => "#{target_directory}tmp/#{uploader.filename}", :image_path => uploader.current_path}
  end
end