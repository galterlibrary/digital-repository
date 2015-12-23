module Sufia
  module Forms
    class BatchEditForm < GalterGenericFileEditForm
      self.terms = self.terms - [:page_number, :doi, :ark]
    end
  end
end
