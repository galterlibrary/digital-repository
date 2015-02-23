class GenericFilePresenter < Sufia::GenericFilePresenter
  self.terms = self.terms + [:abstract, :bibliographic_citation]
end
