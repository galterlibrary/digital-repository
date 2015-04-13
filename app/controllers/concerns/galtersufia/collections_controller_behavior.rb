module Galtersufia
  module CollectionsController
    extend ActiveSupport::Autoload
  end

  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::CollectionsControllerBehavior

    def collection_params
      clean_params = form_class.model_attributes(params[:collection])
      clean_params[:multi_page] = ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(clean_params[:multi_page])
      clean_params
    end

    def presenter_class
      GalterCollectionPresenter
    end

    def form_class
      Sufia::Forms::GalterCollectionEditForm
    end
  end
end
