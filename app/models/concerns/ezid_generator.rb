module EzidGenerator
  extend ActiveSupport::Concern

  attr_accessor :doi_message

  def ezid_metadata(status)
    Ezid::Metadata.new(
      #'datacite.resourcetype' => self.resource_type.first,
      "datacite" => datacite_xml,
      '_status' => status,
      '_target' => "#{ENV['PRODUCTION_URL']}/files/#{self.id}"
    )
  end
  private :ezid_metadata

  def resource_type_map(rtype)
    {
      'Audio Visual Document' => 'Audiovisual',
      'Collections' => 'Collection',
      'Research Paper' => 'DataPaper',
      'Dataset' => 'Dataset',
      'Image' => 'Image',
      'Software or Program Code' => 'Software'
    }[rtype] || 'Other'
  end
  private :resource_type_map

  def datacite_xml(identifier=nil)
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml|
      xml.resource(
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns" => "http://datacite.org/schema/kernel-4",
        "xsi:schemaLocation" => "http://schema.datacite.org/meta/kernel-4/ http://datacite.org/schema/kernel-4/metadata.xsd"
      ) {

        xml.identifier(identifierType: "DOI") {
          xml.text(self.doi.first)
        }

        xml.creators {
          self.creator.each do |creator|
            xml.creator {
              xml.creatorName {
                xml.text(creator)
              }
            }
          end
        }

        xml.titles {
          self.title.each do |title|
            xml.title {
              #xml.text(title)
              xml.text('Is working?')
            }
          end
        }

        xml.publisher {
          xml.text('Galter Health Science Library & Learning Center')
        }

        xml.publicationYear {
          xml.text(
            (self.date_uploaded.try(:year) || Time.zone.today.year).to_s
          )
        }

        xml.resourceType(
          resourceTypeGeneral: resource_type_map(self.resource_type.first)
        ) { xml.text(self.resource_type.first) }

        xml.descriptions {
          self.description.each do |description|
            xml.description(descriptionType: "Abstract") {
              xml.text(description)
            }
          end
        }
      }
    }.to_xml
  end
  private :datacite_xml

  def update_doi_metadata_message(identifier, new_status)
    if new_status == 'unavailable' && identifier.status != new_status
      self.doi_message = 'updated_unavailable'
    else
      self.doi_message = 'updated'
    end

  end
  private :update_doi_metadata_message

  def update_doi_metadata
    self.doi.each do |doi_str|
      begin
        identifier = Ezid::Identifier.find(doi_str.to_s.strip)
        new_status = self.visibility == 'open' ? 'public' : 'unavailable'
        update_doi_metadata_message(identifier, new_status)
        identifier.update_metadata(ezid_metadata(new_status))
        identifier.save
      rescue Ezid::Error
        next
      end
    end
  end
  private :update_doi_metadata

  def can_get_doi?
    # Only generate if required metadata is there
    unless self.id.present? && self.creator.present? && self.title.present?
      self.doi_message = 'metadata'
      return false
    end
    # Only generate for combined pages
    if self.is_a?(Page) && self.page_number.present?
      self.doi_message = 'page'
      return false
    end
    true
  end
  private :can_get_doi?

  def create_doi
    identifier = Ezid::Identifier.mint(ezid_metadata(
      self.visibility == 'open' ? 'public' : 'reserved'))
    self.update_attributes(
      doi: [identifier.id], ark: [identifier.shadowedby])
    self.doi_message = 'generated'
    self.doi_message = 'generated_reserved' if identifier.status == 'reserved'
  end
  private :create_doi

  def check_doi_presence
    return self.doi_message unless can_get_doi?
    if self.doi.present?
      update_doi_metadata
    else
      create_doi
    end
    self.doi_message
  end
end
