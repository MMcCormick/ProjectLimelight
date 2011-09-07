class PagesController < ApplicationController

  def home
    @title = 'Home'
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {})

    #gravatar_url = "http://www.gravatar.com/avatar/#{Digest::MD5.new.update(current_user.email)}?s=512&d=identicon"
    #
    #uploader = ImageUploader.new
    #uploader.store! gravatar_url

    #
    #image = ImageUpload.upload
    #image.upload(gravatar_image)
    #upload.upload_file

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @core_objects }
    end
  end

end
