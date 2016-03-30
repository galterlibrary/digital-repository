module Galtersufia
  module DownloadsController
    extend ActiveSupport::Autoload
  end

  module DownloadsControllerBehavior
    extend ActiveSupport::Concern

    included do
      before_filter :set_cache_buster, :only => :show
    end

    def set_cache_buster
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
  end
end
