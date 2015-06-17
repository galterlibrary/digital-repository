module Galtersufia
  module BatchController
    extend ActiveSupport::Autoload
  end

  module BatchControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::BatchControllerBehavior
    included do
      self.edit_form_class = Sufia::Forms::GalterGenericFileEditForm
    end
  end
end
