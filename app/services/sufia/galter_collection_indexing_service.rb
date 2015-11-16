module Sufia
  class GalterCollectionIndexingService < ActiveFedora::IndexingService
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('label', :sortable)] = object.title.downcase
      end
    end
  end
end
