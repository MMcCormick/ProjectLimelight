class UploadsController < ApplicationController
  def create
    uploader = ImageUploader.new
    uploader.store!(params[:file])
    target_directory = Rails.env.development? ? '/uploads/images/': '/'
    render :json => {:image_location => "#{target_directory}tmp/#{uploader.filename}", :image_path => uploader.current_path}
  end
end