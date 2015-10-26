module Galtersufia
  module CollectionsController
    extend ActiveSupport::Autoload
  end

  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::CollectionsControllerBehavior

    def collection_params
      clean_params = form_class.model_attributes(params[:collection])
      if clean_params.has_key?(:multi_page)
        clean_params[:multi_page] =
          ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(
            clean_params[:multi_page])
      end
      clean_params
    end

    def presenter_class
      GalterCollectionPresenter
    end

    def form_class
      Sufia::Forms::GalterCollectionEditForm
    end

    def show
      if @collection.multi_page && params['sort'].blank?
        params['sort'] = 'page_number_actual_isi asc'
      end
      super
    end

    def edit
      if @collection.multi_page && params['sort'].blank?
        params['sort'] = 'page_number_actual_isi asc'
      end
      super
    end

    # Ugly but allows us to do permissions in the same way
    # as they're done for GenericFile.
    def adjust_permissions
      params['collection'] = {} if params['collection'].blank?

      if params['visibility'].present?
        @collection.visibility = params['visibility']
      end

      if params['generic_file'].try(:[], 'permissions_attributes').present?
        if params['collection']['permissions_attributes'].blank?
          params['collection']['permissions_attributes'] = {}
        end

        params['generic_file']['permissions_attributes'].keys.each do |key|
          if params['collection']['permissions_attributes'][key].blank?
            params['collection']['permissions_attributes'][key] = {}
          end

          params['collection']['permissions_attributes'][key].merge!(
            params['generic_file']['permissions_attributes'][key])
        end
      end
    end
    private :adjust_permissions

    def update
      adjust_permissions
      super
    end

    def after_update_error
      respond_to do |format|
        format.html { redirect_to collections.edit_collection_path(@collection) }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end
end
