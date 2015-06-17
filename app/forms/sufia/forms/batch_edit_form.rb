module Sufia
  module Forms
    class BatchEditForm < GalterGenericFileEditForm
      self.terms = self.terms - [:page_number]
    end
  end
end
