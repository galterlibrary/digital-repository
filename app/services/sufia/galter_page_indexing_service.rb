module Sufia
  class GalterPageIndexingService < GalterGenericFileIndexingService
    def generate_solr_document
      super.tap do |solr_doc|
        #solr_doc[Solrizer.solr_name('tags', :facetable)] = object.all_tags
      end
    end
  end
end
