class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  include InstitutionalCollectionPermissions
  include CleanAttributeValues
  include DoiGenerator
  include SetPublisherValue
  include Galtersufia::GenericFile::FullTextIndexing
  include Galtersufia::GenericFile::MimeTypes

  GV_BLACK_PHOTOGRAPH_SUB_COLLECTION_ID = "x346d4254"
  GV_BLACK_COLLECTION_ID = "a4de96c9-7c6d-40d6-ad9e-cac8a24faad5"

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

  property :doi,
           :predicate => ::RDF::Vocab::Bibframe.doi,
           :multiple => true do |index|
    index.as :stored_searchable
  end

  property :ark,
           :predicate => ::RDF::URI.new(
             'http://galter.northwestern.edu/rdf/ark'),
           :multiple => true do |index|
    index.as :stored_searchable
  end

  property :private_note,
           :predicate => ::RDF::Vocab::MODS.note,
           :multiple => true do |index|
    index.type :text
    index.as :stored_searchable
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
    mesh + lcsh + subject_name + subject_geographic + subject + tag
  end

  def add_doi_to_citation(citation)
    if doi.first.present?
      the_doi = doi.first.to_s.gsub('doi:', '')
      citation.gsub!(/ +$/, '')
      citation << " <a href='https://doi.org/#{the_doi}'>doi:#{the_doi}</a>"
    end
    citation.html_safe
  end
  private :add_doi_to_citation

  def export_as_apa_citation
    citation = super
    add_doi_to_citation(citation)
  end

  def export_as_mla_citation
    citation = super
    add_doi_to_citation(citation)
  end

  def export_as_chicago_citation
    citation = super
    add_doi_to_citation(citation)
  end

  def json_presentation_terms
    GalterGenericFilePresenter.terms -
      [:private_note, :total_items, :size] +
      [:id, :file_size, :file_format]
  end

  def as_json_presentation
    gfjson = json_presentation_terms.inject({}) {|h, term|
      name = I18n.t(:simple_form)[:labels][:generic_file][term] ||
        term.to_s.titleize
      h[name] = self.try(term)
      h
    }
    url_prefix = "https://#{ENV['FULL_HOSTNAME']}"
    gfjson['uri'] = "#{url_prefix}/files/#{self.try(:id)}"
    gfjson['download'] = "#{url_prefix}/downloads/#{self.try(:id)}"
    gfjson
  end

  def unexportable?
     open_access_and_no_doi? || in_old_gv_black_and_not_photograph?
  end

  def in_old_gv_black_and_not_photograph?
    in_collections?([GV_BLACK_COLLECTION_ID]) && !in_collections?([GV_BLACK_PHOTOGRAPH_SUB_COLLECTION_ID])
  end
  private :in_old_gv_black_and_not_photograph?

  def open_access_and_no_doi?
    (visibility == InvenioRdmRecordConverter::OPEN_ACCESS && doi.empty?)
  end
  private :open_access_and_no_doi?

  def in_collections?(collection_array=[])
    !(collection_array & self.collection_ids).empty?
  end

  class << self
    def indexer
      Sufia::GalterGenericFileIndexingService
    end
  end
end
