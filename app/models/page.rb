class Page < GenericFile
  class << self
    def indexer
      Sufia::GalterPageIndexingService
    end
  end
end
