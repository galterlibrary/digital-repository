module Sufia
  class GalterCollectionIndexingService < ActiveFedora::IndexingService
    def generate_solr_document
      super.tap do |solr_doc|
        if object.rights.present?
          solr_doc[Solrizer.solr_name('rights', :facetable)] = object.rights
        end

        if object.title.present?
          solr_doc[
            Solrizer.solr_name('label', :sortable)
          ] = object.title.downcase
        end
      end
    end
  end
end
