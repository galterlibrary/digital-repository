module Sufia
  module Forms
    class GalterCollectionEditForm < CollectionEditForm
      include HydraEditor::Form::Permissions
      self.terms = GalterCollectionPresenter.terms - [
        :total_items, :size]
    end
  end
end
