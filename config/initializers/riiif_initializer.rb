# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new

Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  Riiif::Image.solr_doc_by_id(id)['content_tesim'].first
end

Riiif::Image.info_service = lambda do |id, gf|
  {
    height: gf['height_isim'].try(:first).try(:to_i),
    width: gf['width_isim'].try(:first).try(:to_i),
    scale_factors: [1, 2, 4, 8, 16, 32],
    qualities: ["native", "bitonal", "grey", "color"]
  }
end

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
    include Hydra::Controller::ControllerBehavior
    include Blacklight::Catalog::SearchContext
    include Sufia::Controller
    include Blacklight::SearchHelper
    include Hydra::Controller::SearchBuilder

    before_filter do
      if current_user.blank? || current_user.cannot?(:read, params['id'])
        redirect_to('/users/sign_in')
      else
        @gf = Riiif::Image.solr_doc_by_id(params['id'])
      end
    end

    alias_method :super_show, :show
    def show
      super_show
    end

    def info
      image = model.new(@gf['id'], @gf)
      render json: image.info.merge(server_info)
    end
  end

  Riiif::Image.class_eval do
    class << self
      def solr_doc_by_id(id)
        ActiveFedora::SolrService.query("id:#{id}", rows: 1).first
      end

      def cache_key(id, options)
        # Add version control
        str = options
          .merge(id: id)
          .merge(date: solr_doc_by_id(id)['timestamp'])
          .delete_if {|_, v| v.nil? }.to_s
        # Use a MD5 digest to ensure the keys aren't too long.
        Digest::MD5.hexdigest(str)
      end
    end
  end

end
