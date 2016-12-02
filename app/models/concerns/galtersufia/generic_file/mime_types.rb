module Galtersufia
  module GenericFile
    module MimeTypes
      extend ActiveSupport::Concern

      included do
        include Sufia::GenericFile::MimeTypes
      end

      module ClassMethods
         def audio_mime_types
           super + ['audio/x-ms-wma', 'video/x-ms-asf']
         end
      end
    end
  end
end
