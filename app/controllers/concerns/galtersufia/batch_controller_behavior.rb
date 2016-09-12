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

    def edit_form
      generic_file = ::GenericFile.new(
        creator: [current_user.name],
        title: @batch.generic_files.map(&:label),
        publisher: ['Galter Health Sciences Library, Feinberg School of Medicine, Northwestern University'],
        based_near: ['Chicago, Illinois, United States']
      )
      edit_form_class.new(generic_file)
    end
  end
end
