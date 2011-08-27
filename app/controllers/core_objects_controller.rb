class CoreObjectsController < ApplicationController
  # GET /core_objects
  # GET /core_objects.json
  def index
    @core_objects = CoreObject.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @core_objects }
    end
  end

  # GET /core_objects/1
  # GET /core_objects/1.json
  def show
    @core_object = CoreObject.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @core_object }
    end
  end
end
