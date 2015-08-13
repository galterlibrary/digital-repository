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
    end

    def update
      super
      if response.code == '302'
        response.location = sufia.generic_file_path
      end
    end
  end
end
