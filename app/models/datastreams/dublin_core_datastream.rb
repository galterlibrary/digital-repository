class DublinCoreDatastream < GenericFileRdfDatastream
  property :abstract, predicate: RDF::DC.abstract do |index|
    index.type :text
    index.as :stored_searchable
  end
end
