class UploadsController < ApplicationController
  def create
    uploader = ImageUploader.new
    uploader.store!(params[:file])
    target_directory = Rails.env.development? ? 'http://localhost:3000/uploads/images/': 'http://staging.img.p-li.me/'
    render :json => {:image_location => "#{target_directory}tmp/#{uploader.filename}", :image_path => uploader.current_path}
  end
end