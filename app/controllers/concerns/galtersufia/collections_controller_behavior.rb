module Galtersufia
  module CollectionsController
    extend ActiveSupport::Autoload
  end

  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::CollectionsControllerBehavior

    def collection_params
      form_class.model_attributes(params[:collection])
    end

    def presenter_class
      GalterCollectionPresenter
    end

    def form_class
      Sufia::Forms::GalterCollectionEditForm
    end
  end
end
