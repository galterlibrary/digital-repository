class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include GenericFileHelper
  include Sufia::BatchEditsControllerBehavior

  def destroy_collection
    if cannot? :destroy, ActiveFedora::Base
      after_destroy_collection
      flash[:alert] = "You are not authorized to delete repository objects."
    else
      super
    end
  end
end
