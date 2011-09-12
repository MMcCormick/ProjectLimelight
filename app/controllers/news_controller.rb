class NewsController < ApplicationController
  before_filter :authenticate_user!, :except => [:show]

  # GET /news/1
  # GET /news/1.json
  def show
    @news = News.find_by_encoded_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @news }
    end
  end

  # GET /news/new
  # GET /news/new.json
  def new
    @news = News.new

    respond_to do |format|
      format.html # _new.html.erb
      format.json { render json: @news }
    end
  end

  # GET /news/1/edit
  def edit
    @news = News.find(params[:id])
    #@news.asset_image = AssetImage.new

    if !has_permission(current_user, @news, "edit")
      redirect_to :back, notice: 'You may only edit your own stories!.'
    end
  end

  # POST /news
  # POST /news.json
  def create
    @news = current_user.news.build(params[:news])
    if @news.valid?
      @news.set_user_snippet(current_user)
      @news.set_mentions
      @news.grant_owner(current_user.id)
      # TODO: Use the image_cache if it's there
      @news.save_images(params[:news][:asset_images][:image])
    end

    respond_to do |format|
      if @news.save
        format.html { redirect_to @news, notice: 'News was successfully created.' }
        format.json { render json: @news, status: :created, location: @news }
      else
        format.html { render action: "new" }
        format.json { render json: @news.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /news/1
  # PUT /news/1.json
  def update
    @news = News.find(params[:id])

    if !has_permission(current_user, @news, "edit")
      redirect_to :back, notice: 'You may only edit your own stories!.'
    end

    respond_to do |format|
      if @news.update_attributes(params[:news])
        format.html { redirect_to @news, notice: 'News was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @news.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /news/1
  # DELETE /news/1.json
  def destroy
    @news = News.find(params[:id])

    if !has_permission(current_user, @news, "delete")
      redirect_to :back, notice: 'You may only delete your own stories!'
    end

    @news.delete

    respond_to do |format|
      format.html { redirect_to @news, notice: 'Story successfully deleted.' }
      format.json { head :ok }
    end
  end

end
