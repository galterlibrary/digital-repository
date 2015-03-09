# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new

# This tells RIIIF how to resolve the identifier to a URI in Fedora
DATASTREAM = 'imageContent'
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  #connection = ActiveFedora::Base.connection_for_pid(id)
  #host = connection.config[:url]
  #path = connection.api.datastream_content_url(id, DATASTREAM, {})
  #host + '/' + path
  ::GenericFile.find(id).content.uri
end

# In order to return the info.json endpoint, we have to have the full height and width of
# each image. If you are using hydra-file_characterization, you have the height & width 
# cached in Solr. The following block directs the info_service to return those values:
HEIGHT_SOLR_FIELD = 'height_isi'
WIDTH_SOLR_FIELD = 'width_isi'
Riiif::Image.info_service = lambda do |id, file|
  resp = get_solr_response_for_doc_id id
  doc = resp.first['response']['docs'].first
  byebug
  { height: doc[HEIGHT_SOLR_FIELD], width: doc[WIDTH_SOLR_FIELD] }
end

include Blacklight::SolrHelper
def blacklight_config
  CatalogController.blacklight_config
end

### ActiveSupport::Benchmarkable (used in Blacklight::SolrHelper) depends on a logger method

def logger
  Rails.logger
end


Riiif::Engine.config.cache_duration_in_days = 30
