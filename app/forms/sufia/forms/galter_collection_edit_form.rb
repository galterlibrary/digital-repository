module Sufia
  module Forms
    class GalterCollectionEditForm < CollectionEditForm
      self.terms = GalterCollectionPresenter.terms - [
        :total_items, :size]
    end
  end
end
