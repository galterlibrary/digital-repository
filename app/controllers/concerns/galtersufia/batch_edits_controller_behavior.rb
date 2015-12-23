module Galtersufia
  module BatchEditsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::BatchEditBehavior
    include GenericFileHelper
    include Sufia::BatchEditsControllerBehavior
    include Galtersufia::DoiConcerns

    included do
      before_action :destroy_collection_doi_jobs, :only => :destroy_collection
      before_action :delete_permission_or_redirect, :only => :destroy_collection
      before_action :update_doi_jobs, :only => :update
      before_action :update_delete_check, :only => :update
    end

    def update_doi_jobs
      if params['update_type'] == 'delete_all'
        destroy_collection_doi_jobs
      end
    end
    private :update_doi_jobs

    def destroy_collection_doi_jobs
      batch.each do |doc_id|
        obj = ActiveFedora::Base.find(doc_id, :cast=>true)
        schedule_doi_deactivation_jobs(obj)
      end
    end
    private :destroy_collection_doi_jobs

    def update_delete_check
      return unless params['update_type'] == 'delete_all'
      delete_permission_or_redirect
    end
    private :update_delete_check

    def delete_permission_or_redirect
      if cannot? :destroy, ActiveFedora::Base
        after_destroy_collection
        flash[:alert] = "You are not authorized to delete repository objects."
      end
    end
    private :delete_permission_or_redirect
  end
end
