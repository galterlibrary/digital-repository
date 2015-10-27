# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new

Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  GenericFile.find(id).content.uri
end

Riiif::Image.info_service = lambda do |id, gf|
  {
    height: gf.height.try(:to_i),
    width: gf.width.try(:to_i),
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
      self.search_params_logic += [:add_access_controls_to_solr_params]
      (_, docs) = search_results(
        {q: "id:#{params['id']}"}, self.search_params_logic)
      @gf = docs.try(:first)
      redirect_to('/users/sign_in') if @gf.blank? && current_user.blank?
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
