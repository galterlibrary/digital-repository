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

    def adjust_visibility_update_params?
      required = GenericFilesController.edit_form_class.required_fields
      empty_fields = required.select { |attrib| @generic_file[attrib].blank? }
      return false unless empty_fields.present?
      @generic_file.visibility = 'restricted'
      @generic_file.save!
      alert = 'Please fill out the required fields before changing the visibility: '
      flash['alert'] = alert + empty_fields.join(',')
      true
    end
    private :adjust_visibility_update_params?

    def update
      super
      visibility_adjusted = adjust_visibility_update_params?
      if response.code == '302' && !visibility_adjusted
        response.location = sufia.generic_file_path
      elsif response.code == '302' && visibility_adjusted
        response.location = sufia.edit_generic_file_path
      end
    end

    def show
      super
      if @generic_file.class == Page
        response.headers['X-Robots-Tag'] = 'noindex'
      end
    end
  end
end
