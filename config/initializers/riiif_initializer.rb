# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new

# This tells RIIIF how to resolve the identifier to a URI in Fedora
DATASTREAM = 'imageContent'
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  ::GenericFile.find(id).content.uri
end

# In order to return the info.json endpoint, we have to have the full height and width of
# each image. If you are using hydra-file_characterization, you have the height & width 
# cached in Solr. The following block directs the info_service to return those values:
HEIGHT_SOLR_FIELD = 'height_isi'
WIDTH_SOLR_FIELD = 'width_isi'
Riiif::Image.info_service = lambda do |id, gf|
  gf ||= ::GenericFile.find(id)
  #resp = get_solr_response_for_doc_id id
  #doc = resp.first['response']['docs'].first
  { height: gf.height.try(:first).try(:to_i),
    width: gf.width.try(:first).try(:to_i),
    scale_factors: [1, 2, 4, 8, 16, 32],
    qualities: ["native", "bitonal", "grey", "color"] }
end

# FIXME: Investigate stack level too deep when including this
#include Blacklight::SearchHelper
def blacklight_config
  CatalogController.blacklight_config
end

### ActiveSupport::Benchmarkable (used in Blacklight::SolrHelper) depends on a logger method

def logger
  Rails.logger
end

Riiif::Image.file_resolver.basic_auth_credentials = [
  ENV['FEDORA_USER'],
  ENV['FEDORA_PASS']
]
Riiif::Engine.config.cache_duration_in_days = 30

Rails.configuration.to_prepare do
  Riiif::ImagesController.class_eval do
    before_filter do
      @gf = GenericFile.find(params['id'])
      authorize!(:read, @gf)
    end

    alias_method :super_show, :show
    def show
      super_show
    end

    def info
      image = model.new(@gf.id, @gf)
      render json: image.info.merge(server_info)
    end
  end
end
