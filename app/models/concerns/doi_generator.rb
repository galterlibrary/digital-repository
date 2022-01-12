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
    action, message = get_action_message("draft", self.visibility)
    response = DataciteRest.new.mint(
      datacite_api_json(action)
    )
    data = JSON[response.body]["data"]
    self.update_attributes(doi: [data["id"]])
    self.doi_message = message
  end

  def update_datacite_doi
    client = DataciteRest.new

    self.doi.each do |doi|
      begin
        response = client.get_doi(doi)
        data = JSON[response.body]["data"]
        identifier = data["id"]
        doi_state = data["attributes"]["state"]
        action, message = get_action_message(doi_state, self.visibility)
        json = datacite_api_json(action)
        client.update_metadata(identifier, json)
        self.doi_message = message
      rescue RestClient::NotFound
        next
      end
    end
  end

  def get_action_message(current_doi_state, new_state)
    states = {
      ["draft", "restricted"] => ["", "draft_restricted"], # do nothing
      ["draft", "open"] => ["publish", "draft_published"],
      ["draft", "authenticated"] => ["register", "draft_registered"],
      ["findable", "restricted"] => ["hide", "hide_findable"],
      ["findable", "open"] => ["", "already_findable"], # do nothing
      ["findable", "authenticated"] => ["hide", "hide_findable"],
      ["registered", "restricted"] => ["", "registered_restricted"], # do nothing
      ["registered", "open"] => ["publish", "publish_registered"],
      ["registered", "authenticated"] => ["", "registered_authenticated"] # do nothing
    }
    action = states[[current_doi_state, new_state]][0]
    message = states[[current_doi_state, new_state]][1]
    return action, message
  end

  def datacite_api_json(event="")
    data = {
      "data": {
        "type": "dois",
        "attributes": {
          "event": event,
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
  end

  def set_datacite_prefix(data)
    if !self.doi.present?
      data[:data][:attributes][:prefix] = ENV['DATACITE_DEFAULT_SHOULDER']
    end

    data
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
