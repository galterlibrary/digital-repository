module DoiGenerator
  extend ActiveSupport::Concern

  attr_accessor :doi_message

  def check_doi_presence
    return self.doi_message unless can_get_doi?
    if self.doi.present?
      update_datacite_doi
    else
      create_datacite_doi
    end
    self.doi_message
  end

  private

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

  def create_datacite_doi
    response = DataciteRest.new.mint(
      datacite_api_json
    )
    data = JSON[response.body]["data"]
    self.update_attributes(doi: [data["id"]])
    self.doi_message = 'generated'
    self.doi_message = 'generated_draft' if data["attributes"]["state"] == 'draft'
  end

  def update_datacite_doi
    client = DataciteRest.new

    self.doi.each do |doi|
      response = client.get_doi(doi)
      data = JSON[response.body]["data"]
      identifier = data["id"]
      new_state = visibility_to_state
      current_state = data["attributes"]["state"]
      # if state changes from findable to anything else, we hide it
      if current_state == "findable" && new_state != "findable"
        json = datacite_api_json(hide=true)
      else
        json = datacite_api_json
      end
      client.update_metadata(identifier, json)
      update_doi_metadata_message(current_state, new_state)
    end
  end

  def update_doi_metadata_message(old_state, new_state)
    if new_state == 'registered' && old_state != new_state
      self.doi_message = 'updated_registered'
    else
      self.doi_message = 'updated'
    end

  end

  def datacite_api_json(event=false)
    data = {
      "data": {
        "type": "dois",
        "attributes": {
          "creators": creators_json,
          "titles": titles_json,
          "publisher": self.publisher.first,
          "publicationYear": self.date_uploaded.try(:year) || Time.zone.today.year,
          "types": {
            "resourceType": self.resource_type.first,
            "resourceTypeGeneral": resource_type_map(self.resource_type.first)
          },
          "descriptions": descriptions_json,
          "url": "#{ENV['PRODUCTION_URL']}/files/#{self.id}",
          "schemaVersion": "http://datacite.org/schema/kernel-4"
        }
      }
    }

    set_datacite_prefix(data)
    set_datacite_event(data, event)
  end

  def set_datacite_prefix(data)
    if !self.doi.present?
      data[:data][:attributes][:prefix] = ENV['DATACITE_DEFAULT_SHOULDER']
    end

    data
  end

  def set_datacite_event(data, hide=false)
    state = visibility_to_state

    # More about events in Datacite
    # https://support.datacite.org/docs/api-create-dois#create-a-findable-doi
    if hide
      data[:data][:attributes][:event] = "hide"
    elsif state == "findable"
      data[:data][:attributes][:event] = "publish"
    elsif state == "registered"
      data[:data][:attributes][:event] = "register"
    end

    data
  end

  # Our mapping from Digitalhub visibility to Datacite state
  # https://support.datacite.org/docs/doi-states#doi-states-outside-of-fabrica
  def visibility_to_state
    case self.visibility
    when "restricted"
      "draft"
    when "open"
      "findable"
    when "authenticated"
      "registered"
    end
  end

  def creators_json
    creators = []
    self.creator.each do |creator|
      creators << {"name": creator}
    end
    creators
  end

  def titles_json
    titles = []
    self.title.each do |title|
      titles << {"title": title}
    end
    titles
  end

  def descriptions_json
    descriptions = []
    self.description.each do |description|
      descriptions << {"description": description, "descriptionType": "Abstract"}
    end
    descriptions
  end

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
end
