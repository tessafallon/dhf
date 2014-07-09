class MediaObjectsController < ApplicationController
  include Hydra::Controller::FileAssetsBehavior
       
  before_filter :enforce_access_controls
  before_filter :inject_workflow_steps, only: [:edit, :update]
   
  def new
    logger.debug "<< NEW >>"
    @mediaobject = MediaObject.new
    @mediaobject.avalon_uploader = user_key
    set_default_item_permissions
    @mediaobject.save(:validate => false)

    logger.debug "<< Creating a new Ingest Status >>"
    logger.debug "<< #{@mediaobject.inspect} >>"
    @ingest_status = IngestStatus.create(pid: @mediaobject.pid, current_step: HYDRANT_STEPS.first.step)
    logger.debug "<< There are now #{IngestStatus.count} status in the database >>"
    
    redirect_to edit_media_object_path(@mediaobject, step: HYDRANT_STEPS.first.step)
  end
  
  def edit
    logger.debug "<< EDIT >>"
    logger.info "<< Retrieving #{params[:id]} from Fedora >>"
    
    @mediaobject = MediaObject.find(params[:id])
    @masterFiles = load_master_files
    @currentStream = set_active_file(params[:content])
    if (not @masterFiles.blank? and @currentStream.blank?) then
      @currentStream = @masterFiles.first
      flash[:notice] = "The stream was not recognized. Defaulting to the first available stream for the resource"
    end

    #@masterfiles_with_order = @mediaobject.parts_with_order
    if !@masterFiles.nil? && @masterFiles.count > 1 
      @relType = @mediaobject.descMetadata.relation_type[0]
    end

    @ingest_status = IngestStatus.find_by_pid(@mediaobject.pid)
    @active_step = params[:step] || @ingest_status.current_step
    prev_step = HYDRANT_STEPS.previous(@active_step)
    
    unless prev_step.nil? || @ingest_status.completed?(prev_step.step) 
      redirect_to edit_media_object_path(@mediaobject)
      return
    end
    
    unless @ingest_status.completed?(@active_step)
      @ingest_status.current_step = @active_step
      @ingest_status.save
    end
    
    logger.debug "<< INGEST STATUS => #{@ingest_status.inspect} >>"
    logger.debug "<< ACTIVE STEP => #{@active_step} >>"
    logger.debug "<< There are now #{IngestStatus.count} status in the database >>"
  end
  
  # TODO: Refactor this to reflect the new code model. This is not the ideal way to
  #       handle a multi-screen workflow 
  def update
    logger.debug "<< UPDATE >>"
    logger.info "<< Updating the media object (including a PBCore datastream) >>"
    @mediaobject = MediaObject.find(params[:id])
 
    @ingest_status = IngestStatus.find_by_pid(params[:id])
    @active_step = params[:step] || @ingest_status.current_step
    
    logger.info "<< #{@mediaobject.pid} - #{@active_step} >>"
    logger.debug "<< STEP PARAMETER => #{params[:step]} >>"
    logger.debug "<< ACTIVE STEP => #{@active_step} >>"
    
    case @active_step
      when 'file-upload'
        logger.debug "<< PROCESSING file-upload STEP >>"
        update_master_files(@mediaobject, params[:parts]) unless params[:parts].nil?
        
        unless @mediaobject.parts.empty?
          @mediaobject.format = @mediaobject.parts.first.media_type
          @mediaobject.save(validate: false)
        end

      # When adding resource description
      when 'resource-description' 
        logger.debug "<< Populating required metadata fields >>"
        @mediaobject.update_datastream(:descMetadata, params[:media_object])
        logger.debug "<< Updating descriptive metadata >>"
        @mediaobject.save

      # When on the access control page
      when 'access-control' 
        # TO DO: Implement me
        logger.debug "<< Access flag = #{params[:access]} >>"
	      @mediaobject.access = params[:access]        
        
        @mediaobject.save             
        logger.debug "<< Groups : #{@mediaobject.read_groups} >>"

      when 'structure'
        if !params[:masterfile_ids].nil?
          masterFiles = []
          params[:masterfile_ids].each do |mf_id|
            mf = MasterFile.find(mf_id)
            masterFiles << mf
          end

          # Clean out the parts
          masterFiles.each do |mf|
            @mediaobject.parts_remove mf
          end
          @mediaobject.save(validate: false)
          
          # Puts parts back in order
          masterFiles.each do |mf|
            mf.container = @mediaobject
            mf.save
          end
          @mediaobject.save(validate: false)
        end
       
      # When looking at the preview page use a version of the show page
      when 'preview' 
        # Publish the media object
        @mediaobject.avalon_publisher = user_key
        @mediaobject.save
    end    
    
    unless @mediaobject.errors.empty?
      report_errors
    else
      unless params[:donot_advance] == "true"
        @ingest_status = update_ingest_status(params[:pid], @active_step)
        if HYDRANT_STEPS.has_next?(@active_step)
          @active_step = HYDRANT_STEPS.next(@active_step).step
        elsif @ingest_status.published
          @active_step = "published"
        end
      end

      logger.debug "<< ACTIVE STEP => #{@active_step} >>"
      logger.debug "<< INGEST STATUS => #{@ingest_status.inspect} >>"
      respond_to do |format|
        format.html { (@ingest_status.published and @ingest_status.current?(@active_step)) ? redirect_to(media_object_path(@mediaobject)) : redirect_to(get_redirect_path(@active_step)) }
        format.json { render :json => nil }
      end
    end
  end
  
  def show
    @mediaobject = MediaObject.find(params[:id])

    @masterFiles = load_master_files    
    @currentStream = set_active_file(params[:content])
    if (not @masterFiles.empty? and 
        @currentStream.blank?)
      @currentStream = @masterFiles.first
      flash[:notice] = "That stream was not recognized. Defaulting to the first available stream for the resource"
    end
  end

  def destroy
    @mediaobject = MediaObject.find(params[:id]).delete
    flash[:notice] = "#{params[:id]} has been deleted from the system"
    redirect_to root_path
  end
  
  protected
  def set_default_item_permissions
    unless @mediaobject.rightsMetadata.nil?
      @mediaobject.edit_groups = ['archivist']
      @mediaobject.edit_users = [user_key]
    end
  end
  
  def load_master_files
    logger.debug "<< LOAD MASTER FILES >>"
    logger.debug "<< #{@mediaobject.parts} >>"
    
    @mediaobject.parts
  end
  
  # The goal of this method is to determine which stream to provide to the interface
  # for immediate playback. Eventually this might be replaced by an AJAX call but for
  # now to update the stream you must do a full page refresh.
  #
  # If the stream is not a member of that media object or does not exist at all then
  # return a nil value that needs to be handled appropriately by the calling code
  # block
  def set_active_file(file_pid = nil)
    unless (@mediaobject.parts.blank? or file_pid.blank?)
      @mediaobject.parts.each do |part|
        return part if part.pid == file_pid
      end
    end
      
    # If you haven't dropped out by this point return an empty item
    nil 
  end
  
  def report_errors
    logger.debug "<< Errors found -> #{@mediaobject.errors} >>"
    logger.debug "<< #{@mediaobject.errors.size} >>" 
    
    flash[:error] = "There are errors with your submission. Please correct them before continuing."
    step = params[:step] || HYDRANT_STEPS.first.template
    render :edit and return
  end
  
  def get_redirect_path(target)
    logger.info "<< #{@mediaobject.pid} has been updated in Fedora >>"
    unless HYDRANT_STEPS.last?(params[:step])
      redirect_path = edit_media_object_path(@mediaobject, step: target)
    else
      flash[:notice] = "This resource is now available for use in the system"
      redirect_path = media_object_path(@mediaobject)
      return
    end
    redirect_path
  end
  
  def inject_workflow_steps
    logger.debug "<< Injecting the workflow into the view >>"
    @workflow_steps = HYDRANT_STEPS
  end
  
  def update_ingest_status(pid, active_step=nil)
    logger.debug "<< UPDATE_INGEST_STATUS >>"
    logger.debug "<< Updating current ingest step >>"
    
    if @ingest_status.nil?
      @ingest_status = IngestStatus.find_or_create(pid: @mediaobject.pid)
    else
      active_step = active_step || @ingest_status.current_step
      logger.debug "<< COMPLETED : #{@ingest_status.completed?(active_step)} >>"
      
      if HYDRANT_STEPS.last? active_step and @ingest_status.completed? active_step
        @ingest_status.publish
      end
      logger.debug "<< PUBLISHED : #{@ingest_status.published} >>"

      if @ingest_status.current?(active_step) and not @ingest_status.published
        logger.debug "<< ADVANCING to the next step in the workflow >>"
        logger.debug "<< #{active_step} >>"
        @ingest_status.current_step = @ingest_status.advance
      end
    end

    @ingest_status.save
    @ingest_status
  end
  
  # Passing in an ordered array of values update the master files below a
  # MediaObject. Accepted hash keys are
  #
  # remove - Set to true to delete this item
  # label - Display label in the interface
  # pid - Identifier for the masterFile to help with mapping
  def update_master_files(mediaobject, files = [])
        logger.debug "<< files => #{files} >>"
        if not files.blank?
          files.each do |part|
            logger.debug "<< #{part} >>"
            selected_part = nil
            mediaobject.parts.each do |current_part|
              selected_part = current_part if current_part.pid == part[:pid]
            end
            next unless not selected_part.blank?
            
            if part[:remove]
              logger.info "<< Deleting master file #{part[:pid]} from the system >>"
              selected_part.delete
            else
              selected_part.label = part[:label]
              selected_part.save
            end            
          end
        end
  end
end
