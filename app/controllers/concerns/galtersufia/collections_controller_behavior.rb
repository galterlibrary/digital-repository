module Galtersufia
  module CollectionsController
    extend ActiveSupport::Autoload
  end

  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::CollectionsControllerBehavior

    included do
      skip_before_action :authenticate_user!, :only => :index
      skip_authorize_resource :only => :update
      load_resource :only => :update
      before_filter :update_authorization, :only => :update
      after_filter :on_member_change, :only => :update
      after_filter :notify_on_update, :only => :update
      after_filter :notify_on_create, :only => :create
      after_filter :notify_on_destroy, :only => :destroy
    end

    def notify_on_destroy
      return if params['batch_document_ids'].present?
      Sufia.queue.push(
        CollectionDeleteEventJob.new(params[:id], current_user.user_key)
      )
    end

    def notify_on_create
      return if params['batch_document_ids'].present?
      # Can't get this to work even when job is delayed, object is not found
      #Sufia.queue.push(
      #  CollectionCreateEventJob.new(params[:id], current_user.user_key)
      #)
    end

    def notify_on_update
      return if params['batch_document_ids'].present?
      Sufia.queue.push(
        CollectionUpdateEventJob.new(params[:id], current_user.user_key)
      )
    end

    def on_member_change
      return if params['collection'].blank?
      return if params['batch_document_ids'].blank?
      jobs = []
      if params['collection']['members'] == 'add'
        params['batch_document_ids'].each do |member_id|
          jobs << AddInstitutionalAdminPermissionsJob.new(
            member_id, params[:id]
          )
          jobs << CollectionUploadEventJob.new(
            params[:id], member_id, current_user.user_key
          )
        end
      elsif params['collection']['members'] == 'remove'
        params['batch_document_ids'].each do |member_id|
          jobs << RemoveInstitutionalAdminPermissionsJob.new(
            member_id, params[:id]
          )
          jobs << CollectionMemberRemoveEventJob.new(
            params[:id], member_id, current_user.user_key
          )
        end
      end
      jobs.each {|job| Sufia.queue.push(job) }
    end
    private :on_member_change

    def update_authorization
      if cannot?(:update, @collection)
        filter_params_for_institutions
        authorize!(:add_members, @collection)
      else
        if params['collection'].try(:[], 'members') == 'remove'
          authorize!(:remove_members, params['batch_document_ids'])
        end
      end
    end
    private :update_authorization

    def filter_params_for_institutions
      params['collection'] = { 'members' => 'add' }
    end
    private :filter_params_for_institutions

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
      if params['sort'].blank?
        if @collection.multi_page
          params['sort'] = 'page_number_actual_isi asc'
        else
          params['sort'] = 'label_si asc'
        end
      end
      respond_to do |format|
        format.html {
          super
        }
        format.json {
          params['per_page'] = @collection.members.count.to_s
          super
          render json: @collection.as_json_presentation(@member_docs)
        }
      end
    end

    def collection_member_search_logic
      if current_user.present? && current_user.is_admin?
        super - [:add_access_controls_to_solr_params]
      else
        super
      end
    end

    def edit
      if @collection.multi_page && params['sort'].blank?
        params['sort'] = 'page_number_actual_isi asc'
      end
      super
    end

    def index_collections_search_builder(access_level = nil)
      @collections_search_builder ||= collections_search_builder_class.new(
          index_collection_params_logic, self).tap do |builder|
        builder.current_ability = current_ability
        builder.discovery_perms = access_levels[access_level] if access_level
      end
    end

    def index_collection_params_logic
      [
        :default_solr_parameters,
        :add_query_to_solr,
        :add_access_controls_to_solr_params,
        :add_collection_filter,
        :all_rows,
        :add_sorting_to_solr
      ]
    end


    def collections_search_builder_class
      GalterCollectionsSearchBuilder
    end

    def index
      params[:sort] = "label_si asc"
      index_collections_search_builder
      query = collections_search_builder.with(params).query
      @response = repository.search(query)
      @document_list = @response['response']['docs']
      flash['notice'] = nil
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

    def follow
      if @collection.set_follower(current_user)
        flash[:notice] = "You now follow #{collection.title}"
      else
        flash[:alert] = "There was a problem trying to follow the collection"
      end
        redirect_to collections.collection_path(@collection)
    end

    def unfollow
      if @collection.remove_follower(current_user)
        flash[:notice] = "You stopped following #{collection.title}"
      else
        flash[:alert] = "There was a problem trying to stop following the collection"
      end
      redirect_to collections.collection_path(@collection)
    end
  end
end
