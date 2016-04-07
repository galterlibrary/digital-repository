module Galtersufia
  module DownloadsController
    extend ActiveSupport::Autoload
  end

  module DownloadsControllerBehavior
    extend ActiveSupport::Concern

    def show
      super
    end

    def file_name
      if !params[:file] || params[:file] == self.class.default_file_path
        params[:filename] || file.original_name || asset.label
      else
        params[:file]
      end
    end
  end
end
