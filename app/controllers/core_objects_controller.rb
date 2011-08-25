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

  # GET /core_objects/new
  # GET /core_objects/new.json
  def new
    @core_object = CoreObject.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @core_object }
    end
  end

  # GET /core_objects/1/edit
  def edit
    @core_object = CoreObject.find(params[:id])
  end

  # POST /core_objects
  # POST /core_objects.json
  def create
    @core_object = CoreObject.new(params[:core_object])

    respond_to do |format|
      if @core_object.save
        format.html { redirect_to @core_object, notice: 'Core object was successfully created.' }
        format.json { render json: @core_object, status: :created, location: @core_object }
      else
        format.html { render action: "new" }
        format.json { render json: @core_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /core_objects/1
  # PUT /core_objects/1.json
  def update
    @core_object = CoreObject.find(params[:id])

    respond_to do |format|
      if @core_object.update_attributes(params[:core_object])
        format.html { redirect_to @core_object, notice: 'Core object was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @core_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /core_objects/1
  # DELETE /core_objects/1.json
  def destroy
    @core_object = CoreObject.find(params[:id])
    @core_object.destroy

    respond_to do |format|
      format.html { redirect_to core_objects_url }
      format.json { head :ok }
    end
  end
end
