class CrawlerSourcesController < ApplicationController
  # GET /crawler_sources
  # GET /crawler_sources.json
  def index
    @crawler_sources = CrawlerSource.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @crawler_sources }
    end
  end

  # GET /crawler_sources/1
  # GET /crawler_sources/1.json
  def show
    @crawler_source = CrawlerSource.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @crawler_source }
    end
  end

  # GET /crawler_sources/new
  # GET /crawler_sources/new.json
  def new
    @crawler_source = CrawlerSource.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @crawler_source }
    end
  end

  # GET /crawler_sources/1/edit
  def edit
    @crawler_source = CrawlerSource.find(params[:id])
  end

  # POST /crawler_sources
  # POST /crawler_sources.json
  def create
    @crawler_source = CrawlerSource.new(params[:crawler_source])

    respond_to do |format|
      if @crawler_source.save
        format.html { redirect_to @crawler_source, notice: 'Crawler source was successfully created.' }
        format.json { render json: @crawler_source, status: :created, location: @crawler_source }
      else
        format.html { render action: "new" }
        format.json { render json: @crawler_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /crawler_sources/1
  # PUT /crawler_sources/1.json
  def update
    @crawler_source = CrawlerSource.find(params[:id])

    respond_to do |format|
      if @crawler_source.update_attributes(params[:crawler_source])
        format.html { redirect_to @crawler_source, notice: 'Crawler source was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @crawler_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /crawler_sources/1
  # DELETE /crawler_sources/1.json
  def destroy
    @crawler_source = CrawlerSource.find(params[:id])
    @crawler_source.destroy

    respond_to do |format|
      format.html { redirect_to crawler_sources_url }
      format.json { head :no_content }
    end
  end
end
