class Collection < Sufia::Collection
  include Hydra::Collections::Actions
  include InstitutionalCollectionPermissions
  include CleanAttributeValues

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

  property :institutional_collection,
           :predicate => ::RDF::URI.new(
             'http://galter.northwestern.edu/rdf/institutional_collection'),
           :multiple => false do |index|
    index.as :stored_searchable
    index.type :boolean
  end

  property :private_note,
           :predicate => ::RDF::Vocab::MODS.note,
           :multiple => true do |index|
    index.type :text
    index.as :stored_searchable
  end

  def pageable?
    multi_page && pageable_members.present?
  end

  def pageable_members
    rows = members.count
    return [] if rows == 0

    raise "Collection must be saved to query for pageable members" if new_record?

    query = '(has_model_ssim:Page OR has_model_ssim:GenericFile) AND page_number_actual_isi:[1 TO *]'
    args = {
      fq: "{!join from=hasCollectionMember_ssim to=id}id:#{id}",
      fl: 'id',
      rows: rows,
      sort: 'page_number_actual_isi asc'
    }

    ActiveFedora::SolrService.query(query, args).map do |gf_id|
      ActiveFedora::SolrService.query(
        "id:#{gf_id['id']}", { rows: rows }
      ).first
    end
  end

  def processing?
  end

  def osd_tile_sources
    return [] unless pageable?
    pageable_members.map {|gf| "/image-service/#{gf['id']}/info.json" }
  end

  def file_size_field
    Solrizer.solr_name('file_size', :stored_long)
  end

  def members_from_solr
    raise "Collection must be saved to query for bytes" if new_record?

    query = '_query_:"{!raw f=has_model_ssim}Page" OR _query_:"{!raw f=has_model_ssim}GenericFile"'
    args = {
      fq: "{!join from=hasCollectionMember_ssim to=id}id:#{id}",
      fl: "id, #{file_size_field}",
      rows: members.count
    }

    ActiveFedora::SolrService.query(query, args)
  end

  def bytes
    return 0 if members.count == 0
    files = members_from_solr
    files.reduce(0) { |sum, f| sum + f[file_size_field].to_i }
  end

  def is_institutional?
    self.institutional_collection
  end

  def traverse(&block)
    yield self
    self.members.flatten.compact.each do |child|
      if child.is_a?(Collection)
        child.traverse(&block)
      else
        yield child
      end
    end
  end

  def all_tags
    mesh + lcsh + subject_name + subject_geographic + subject + tag
  end

  # Hacks for collection followers
  def self.type_for_attribute(attr)
    ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer.new
  end

  def self.primary_key
    'id'
  end
  # Hacks for collection followers ends

  def followers
    Follow.where(followable_fedora_id: self.id,
                 followable_type: 'Collection').map {|f|
      next unless f.follower_type == 'User'
      User.find(f.follower_id)
    }.compact.uniq
  end

  def set_follower(user)
    return false unless user.present?
    Follow.find_or_create_by(
      followable_fedora_id: self.id,
      followable_type: 'Collection',
      follower_id: user.id,
      follower_type: 'User'
    )
  end

  def remove_follower(user)
    return false unless user.present?
    Follow.where(
      followable_fedora_id: self.id,
      followable_type: 'Collection',
      follower_id: user.id,
    ).first.try(:destroy)
  end

  def json_from_solr(doc)
    terms = json_presentation_terms_gf
    o_type = :generic_file
    if doc['active_fedora_model_ssi'] == 'Collection'
      o_type = :collection
      terms = json_presentation_terms
    end

    fixed_doc = doc.inject({}) {|h, (k,v)|
      t_part = k.rpartition('_')
      term = t_part.first.present? ? t_part.first : k
      h[term] = v
      h
    }

    o_json = terms.inject({}) {|h, term|
      name = I18n.t(:simple_form)[:labels][o_type][term] ||
        term.to_s.titleize
      h[name] = fixed_doc[term.to_s]
      h
    }

    url_prefix = "https://#{ENV['FULL_HOSTNAME']}"
    if o_type == :collection
      o_json['uri'] = "#{url_prefix}/collections/#{o_json['Id']}"
    else
      o_json['uri'] = "#{url_prefix}/files/#{o_json['Id']}"
      o_json['download'] = "#{url_prefix}/downloads/#{o_json['Id']}"
    end

    o_json
  end

  def json_presentation_terms
    GalterCollectionPresenter.terms -
      [:private_note, :total_items, :size] +
      [:id]
  end

  def json_presentation_terms_gf
    GalterGenericFilePresenter.terms -
      [:private_note, :total_items, :size] +
      [:id, :file_size, :file_format]
  end

  def as_json_presentation(member_docs = nil)
    cjson = json_presentation_terms.inject({}) {|h, term|
      name = I18n.t(:simple_form)[:labels][:collection][term] ||
        term.to_s.titleize
      h[name] = self.try(term)
      h
    }
    url_prefix = "https://#{ENV['FULL_HOSTNAME']}"
    cjson['uri'] = "#{url_prefix}/collections/#{self.try(:id)}"

    if member_docs
      cjson[:members] = member_docs.map {|m| json_from_solr(m) }
    else
      # FIXME not implemented
      cjson[:members] = []
    end
    cjson
  end

  class << self
    def indexer
      Sufia::GalterCollectionIndexingService
    end
  end
end
