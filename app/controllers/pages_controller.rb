class PagesController < ApplicationController

  def home
    @title = 'Home'
    page = params[:p] ? params[:p].to_i : 1
    @more_path = root_path :p => page + 1
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {:page => page})

    #gravatar_url = "http://www.gravatar.com/avatar/#{Digest::MD5.new.update(current_user.email)}?s=512&d=identicon"
    #
    #uploader = ImageUploader.new
    #uploader.store! gravatar_url

    #
    #image = ImageUpload.upload
    #image.upload(gravatar_image)
    #upload.upload_file

    respond_to do |format|
      if request.xhr?
        html =  render_to_string :partial => "core_objects/feed", :locals => { :more_path => @more_path }
        format.json { render json: { :event => "loaded_feed_page", :content => html } }
      else
        format.html # index.html.erb
        format.json { render json: @core_objects }
      end
    end
  end

end
