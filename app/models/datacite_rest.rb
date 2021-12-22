require 'rest-client'

class DataciteRest
  def initialize
    endpoint = ENV['DATACITE_API']
    username = ENV['EZID_USER']
    password = ENV['EZID_PASSWORD']
    @resource = RestClient::Resource.new(endpoint, username, password)
  end

  def list_dois
    @resource["dois"].get
  end

  def get_doi(doi)
    @resource["dois/#{doi}"].get
  end

  def mint(json_data_string)
    @resource['dois'].post(json_data_string, content_type: 'application/vnd.api+json')
  end

  def update_metadata(doi, json_data_string)
    @resource["dois/#{doi}"].put(json_data_string, content_type: 'application/vnd.api+json')
  end
end
