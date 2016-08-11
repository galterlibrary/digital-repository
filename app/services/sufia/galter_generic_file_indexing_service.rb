module Sufia
  class GalterGenericFileIndexingService < GenericFileIndexingService
    def generate_solr_document
      super.tap do |solr_doc|
        if object.content.present?
          solr_doc[Solrizer.solr_name('content')] = object.content.uri.to_s
        end

        solr_doc.delete(Solrizer.solr_name('file_size', :stored_integer))
        Solrizer.insert_field(
          solr_doc,
          'file_size',
          object.content.size.to_i,
          :stored_long
        )

        solr_doc[Solrizer.solr_name('tags', :facetable)] = object.all_tags

        solr_doc[
          Solrizer.solr_name(:width, :type => :integer)
        ] = object.width

        solr_doc[
          Solrizer.solr_name(:height, :type => :integer)
        ] = object.height

        if object.rights.present?
          solr_doc[Solrizer.solr_name('rights', :facetable)] = (
            object.rights.map {|cr| Sufia.config.cc_licenses.key(cr) }
          )
        end

        if object.title.present?
          solr_doc[
            Solrizer.solr_name('label', :sortable)
          ] = object.title.first.downcase
        end
      end
    end
  end
end
