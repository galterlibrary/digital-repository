module EzidGenerator
  extend ActiveSupport::Concern

  attr_accessor :doi_message

  def ezid_metadata(status)
    Ezid::Metadata.new(
      'datacite.creator' => self.creator.first,
      'datacite.title' => self.title.first,
      'datacite.publisher' => 'Galter Health Science Library',
      'datacite.publicationyear' =>
        (self.date_uploaded.try(:year) || Time.zone.today.year).to_s,
      #'datacite.resourcetype' => self.resource_type.first,
      '_status' => status,
      '_target' => "#{ENV['PRODUCTION_URL']}/files/#{self.id}"
    )
  end
  private :ezid_metadata

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
