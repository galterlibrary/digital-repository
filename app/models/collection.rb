class Collection < Sufia::Collection
  include Hydra::Collections::Actions

  before_create :open_visibility

  def open_visibility
    self.visibility = 'open'
  end
  private :open_visibility

  def update_permissions
  end

  has_many :children, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf,
    class_name: 'ActiveFedora::Base'
  belongs_to :parent, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf,
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

  property :subject_geographic, predicate: ::RDF::Vocab::MODS.subjectGeographic, multiple: true do |index|
    index.as :stored_searchable
  end

  property :subject_name, predicate: ::RDF::Vocab::MODS.subjectName, multiple: true do |index|
    index.as :stored_searchable
  end

  property :page_number, predicate: ::RDF::URI.new('http://opaquenamespace.org/hydra/pageNumber'), multiple: false do |index|
    index.as :stored_searchable
    index.type :integer
  end

  property :multi_page, predicate: ::RDF::URI.new('http://opaquenamespace.org/hydra/multiPage'), multiple: false do |index|
    index.as :stored_searchable
    index.type :boolean
  end

  def pagable?
    multi_page && pagable_members.present?
  end

  def pagable_members
    members.reject {|o| o.page_number.blank? }.sort_by {|o| o.page_number.to_i }
  end

  def bytes
    'FIXME in app/models/collection.rb'
  end

  def processing?
  end

  def osd_tile_sources
    return [] unless pagable?
    pagable_members.map {|gf| "/image-service/#{gf.id}/info.json" }
  end
end
