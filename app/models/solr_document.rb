# -*- encoding : utf-8 -*-
class SolrDocument
  include Blacklight::Solr::Document
  include Sufia::SolrDocumentBehavior
  include Blacklight::Gallery::OpenseadragonSolrDocument
  include Galtersufia::GenericFile::MimeTypes

  # self.unique_key = 'id'
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)

  def width
     Array(self[Solrizer.solr_name(:width, :type => :integer)]).first
  end

  def height
     Array(self[Solrizer.solr_name(:height, :type => :integer)]).first
  end

  def member_ids
    Array(self['hasCollectionMember_ssim'])
  end
end
