class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  property :abstract, predicate: ::RDF::DC.abstract, multiple: true do |index|
    index.type :text
    index.as :stored_searchable
  end
end
