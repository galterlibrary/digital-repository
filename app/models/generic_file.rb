class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile
  has_metadata 'descMetadata', type: DublinCoreDatastream
  has_attributes :description, :abstract, datastream: 'descMetadata', multiple: true
  attr_accessible :resource_type, :title, :creator, :contributor, :description,
    :tag, :rights, :publisher, :date_created, :subject, :language, :identifier,
    :based_near, :related_url, :abstract

  def terms_for_display
    super + [:abstract]
  end
end
