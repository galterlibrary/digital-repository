class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  has_metadata 'descMetadata', type: DublinCoreDatastream
  has_attributes :bibliographic_citation, :abstract,
    datastream: 'descMetadata', multiple: true
  attr_accessible :resource_type, :title, :creator, :contributor, :description,
    :tag, :rights, :publisher, :date_created, :subject, :language, :identifier,
    :based_near, :related_url, :abstract, :bibliographic_citation

  def terms_for_display
    super + [:abstract, :bibliographic_citation]
  end
end
