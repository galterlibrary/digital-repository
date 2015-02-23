module Galtersufia
  module FilesController
    extend ActiveSupport::Autoload
    include Sufia::FilesController
  end

  module FilesControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::FilesControllerBehavior
    included do
      #Uncomment after upgrade past RC2 and remove the presenter method
      #self.presenter_class = GenericFilePresenter
      # Sufia::Forms::GenericFileEditForm should work after upgrade
      # but we should rename it so it's clear
      #self.edit_form_class = Sufia::Forms::GenericFileEditForm
    end

    def presenter
      GenericFilePresenter.new(@generic_file)
    end
  end
end
