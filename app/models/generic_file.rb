class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  belongs_to :parent,
    predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf,
    class_name: "Collection"

  belongs_to :combined_file,
    predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasEquivalent,
    class_name: "Collection"

  property :abstract, predicate: ::RDF::DC.abstract, multiple: true do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :acknowledgments,
           :predicate => ::RDF::URI.new(
             'http://galter.northwestern.edu/rdf/acknowledgments'),
           :multiple => true do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :grants_and_funding,
           :predicate => ::RDF::URI.new(
             'http://galter.northwestern.edu/rdf/grants_and_funding'),
           :multiple => true do |index|
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

  property :subject_geographic,
           :predicate => ::RDF::URI.new(
             'http://id.worldcat.org/fast/ontology/1.0/#facet-Geographic'),
           :multiple => true do |index|
    index.as :stored_searchable
  end

  property :subject_name,
           :predicate => ::RDF::URI.new('http://id.loc.gov/authorities/names'),
           :multiple => true do |index|
    index.as :stored_searchable
  end

  property :page_number,
           :predicate => ::RDF::URI.new(
             'http://www.w3.org/TR/xmlschema-2/#string'),
           :multiple => false do |index|
    index.as :stored_searchable
    index.type :string
  end

  property :page_number_actual,
           :predicate => ::RDF::URI.new(
             'http://www.w3.org/TR/xmlschema-2/#integer'),
           :multiple => false do |index|
    index.as :stored_sortable
    index.type :integer
  end

  before_save :store_the_actual_page_number

  def store_the_actual_page_number
    if self.page_number_actual_changed?
      self.page_number_actual = Integer(page_number_actual) rescue nil
    elsif self.page_number_changed?
      self.page_number_actual = Integer(page_number) rescue nil
    end
  end
  protected :store_the_actual_page_number

  def all_tags
    mesh + lcsh + subject_name + subject_geographic
  end

  class << self
    def indexer
      Sufia::GalterGenericFileIndexingService
    end
  end
end
