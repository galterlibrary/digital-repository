module Galtersufia
  module BatchEditsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::BatchEditBehavior
    include GenericFileHelper
    include Sufia::BatchEditsControllerBehavior

    included do
      before_action :delete_permission_or_redirect, :only => :destroy_collection
      before_action :update_delete_check, :only => :update
    end

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
