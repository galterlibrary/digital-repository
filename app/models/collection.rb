class Collection < Sufia::Collection
  include Hydra::Collections::Actions

  validates :tag, presence: true
  before_create :open_visibility

  def open_visibility
    self.visibility = 'open'
  end
  private :open_visibility

  def update_permissions
  end

  has_many :children,
    predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf,
    class_name: 'ActiveFedora::Base'

  belongs_to :parent,
    predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf,
    class_name: 'Collection'

  belongs_to :combined_file,
    predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasEquivalent,
    class_name: 'GenericFile'

  property :abstract, predicate: ::RDF::DC.abstract, multiple: true do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :bibliographic_citation, predicate: ::RDF::DC.bibliographicCitation do |index|
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

  property :multi_page,
           :predicate => ::RDF::URI.new(
             'http://www.w3.org/TR/xmlschema-2/#boolean'),
           :multiple => false do |index|
    index.as :stored_searchable
    index.type :boolean
  end

  def pagable?
    multi_page && pagable_members.present?
  end

  def pagable_members
    members.reject {|o|
      !o.respond_to?(:page_number) || o.page_number.blank?
    }.sort_by {|o| o.page_number.to_i }
  end

  def processing?
  end

  def osd_tile_sources
    return [] unless pagable?
    pagable_members.map {|gf| "/image-service/#{gf.id}/info.json" }
  end

  def file_model
    if multi_page
      ::Page.to_class_uri
    else
      super
    end
  end
end
