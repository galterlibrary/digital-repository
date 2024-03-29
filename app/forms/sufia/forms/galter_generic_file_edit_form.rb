module Sufia
  module Forms
    class GalterGenericFileEditForm < GalterGenericFilePresenter
      include HydraEditor::Form
      include HydraEditor::Form::Permissions
      self.required_fields = [:title, :creator, :tag, :rights, :resource_type]
      self.terms = GalterGenericFilePresenter.terms - [:digital_origin]
    end
  end
end
