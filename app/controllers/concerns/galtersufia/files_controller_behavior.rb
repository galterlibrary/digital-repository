module Galtersufia
  module FilesController
    extend ActiveSupport::Autoload
    include Sufia::FilesController
  end

  module FilesControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::FilesControllerBehavior

    included do
      self.presenter_class = GalterGenericFilePresenter
      self.edit_form_class = Sufia::Forms::GalterGenericFileEditForm
      before_action :mark_as_dirty, only: [:update]
      after_action :purge_riiif_cache_and_update_index, only: [:update]
      around_action :update_doi_jobs, only: [:update]
      after_action :add_institutional_permissions, only: [:create]
    end

    def add_institutional_permissions
      unless params[:collection] == '-1'
        Sufia.queue.push(
          AddInstitutionalAdminPermissionsJob.new(
            actor.generic_file.id, params[:collection])
        )
      end
    end
    private :add_institutional_permissions

    def mark_as_dirty
      # modified_date doesn't get updated when adding more then one
      # version of content and that messes with cache
      @generic_file.mark_as_changed(:label)
    end
    protected :mark_as_dirty

    def purge_riiif_cache_and_update_index
      return unless params['revision'].present? || params['filedata'].present?
      return unless @generic_file.content.present?
      cache_file_name = Digest::MD5.hexdigest(@generic_file.content.uri)
      cache_file = ::File.join('tmp/network_files', cache_file_name)
      if ::File.exist?(cache_file)
        ::File.delete(cache_file)
      end
      @generic_file.update_index
    end
    protected :purge_riiif_cache_and_update_index

    def update_doi_jobs
      yield
      Sufia.queue.push(
        MintDoiJob.new(@generic_file.id, current_user.username))
    end
    private :update_doi_jobs

    def adjust_visibility_update_params?
      required = GenericFilesController.edit_form_class.required_fields
      empty_fields = required.select { |attrib| @generic_file[attrib].blank? }
      return false unless empty_fields.present?
      @generic_file.visibility = 'restricted'
      @generic_file.save!
      alert = 'Please fill out the required fields before changing the visibility: '
      flash['alert'] = alert + empty_fields.join(',')
      true
    end
    private :adjust_visibility_update_params?

    def update
      super
      visibility_adjusted = adjust_visibility_update_params?
      if response.code == '302' && !visibility_adjusted
        response.location = sufia.generic_file_path
      elsif response.code == '302' && visibility_adjusted
        response.location = sufia.edit_generic_file_path
      end
    end

    def new
      set_variables_for_new_form
      @batch_id = SecureRandom.uuid
    end

    def show
      respond_to do |format|
        format.html { super }
        format.endnote { super }
        format.json {
          render json: @generic_file.as_json_presentation
        }
      end

      if @generic_file.class == Page
        response.headers['X-Robots-Tag'] = 'noindex'
      end
    end
  end
end
