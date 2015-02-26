class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  property :abstract, predicate: ::RDF::DC.abstract, multiple: true do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :digital_origin, predicate: ::RDF::Vocab::MODS.digitalOrigin, multiple: true do |index|
    index.as :stored_searchable
  end

  property :mesh, predicate: ::RDF::DC.MESH, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :lcsh, predicate: ::RDF::DC.LCSH, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_geographic, predicate: ::RDF::Vocab::MODS.subjectGeographic, multiple: true do |index|
    index.as :stored_searchable
  end

  property :subject_name, predicate: ::RDF::Vocab::MODS.subjectName, multiple: true do |index|
    index.as :stored_searchable
  end
end
