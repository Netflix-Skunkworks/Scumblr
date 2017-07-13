class SystemMetadataController < ApplicationController
  before_action :set_system_metadatum, only: [:show, :edit, :update, :destroy, :autocomplete]
  #serialize :metadata, JSON

  # GET /system_metadata
  # GET /system_metadata.json
  authorize_resource class: "SystemMetadata"
  def index
    @system_metadata = SystemMetadata.all
  end

  # GET /system_metadata/1
  # GET /system_metadata/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @system_metadata }
    end
  end

  # GET /system_metadata/new
  def new
    @system_metadata = SystemMetadata.new
  end

  # GET /system_metadata/1/edit
  def edit

  end

  def autocomplete
    if(params[:q].blank?)
      data = []
    else
      data = @system_metadata.metadata
      if(params[:key])
        data = data.try(:[], params[:key])
      end
      
      data = data.select{ |d| 
        if(d.class==Hash)
          d.values.to_s.match(/#{params[:q]}/i)
        else
          d.to_s.match(/#{params[:q]}/i)
        end
      } if data
      paginated_data = Kaminari.paginate_array(data).page(params[:page]).per(params[:per_page])
    end


    respond_to do |format|
      format.json { render json: {results: paginated_data, meta:{total: data.count}}}
    end
      
  end

  # POST /system_metadata
  # POST /system_metadata.json
  def create
    @system_metadata = SystemMetadata.new(system_metadatum_params)

    respond_to do |format|
      if @system_metadata.save
        format.html { redirect_to @system_metadata, notice: 'System metadata was successfully created.' }
        format.json { render :show, status: :created, location: @system_metadata }
      else
        format.html { render :new }
        format.json { render json: @system_metadata.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /system_metadata/1
  # PATCH/PUT /system_metadata/1.json
  def update
    respond_to do |format|
      if @system_metadata.update(system_metadatum_params)
        format.html { redirect_to @system_metadata, notice: 'System metadata was successfully updated.' }
        format.json { render :show, status: :ok, location: @system_metadata }
      else
        format.html { render :edit }
        format.json { render json: @system_metadata.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_metadata/1
  # DELETE /system_metadata/1.json
  def destroy
    @system_metadata.destroy
    respond_to do |format|
      format.html { redirect_to system_metadata_url, notice: 'System metadata was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_system_metadatum
    @system_metadata = SystemMetadata.find(params[:id])

  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def system_metadatum_params
    params.fetch(:system_metadata, {}).permit(:key, :metadata_raw)
  end
end
