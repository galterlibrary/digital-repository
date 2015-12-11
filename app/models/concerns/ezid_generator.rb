module EzidGenerator
  extend ActiveSupport::Concern

  def check_doi_presence
    return unless self.id.present? &&
                  self.creator.present? &&
                  self.title.present?
    return if self.doi.present?
    metadata = Ezid::Metadata.new(
      'datacite.creator' => self.creator.first,
      'datacite.title' => self.title.first,
      'datacite.publisher' => 'Galter Health Science Library',
      'datacite.publicationyear' =>
        (self.date_uploaded.try(:year) || Time.zone.today.year).to_s,
      '_target' => "#{ENV['PRODUCTION_URL']}/files/#{self.id}"
    )
    identifier = Ezid::Identifier.create(metadata)
    self.update_attributes(doi: [identifier.id], ark: [identifier.shadowedby])
  end
end
