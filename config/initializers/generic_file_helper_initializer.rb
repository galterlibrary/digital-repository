Rails.configuration.to_prepare do
  GenericFileHelper.class_eval do
    def download_image_tag(title = nil)
      content_tag :figure do
        if title.nil?
          concat image_tag(
            "default.png",
            alt: "No preview available",
            class: "img-responsive"
          )
        else
          concat image_tag(
            sufia.download_path(@generic_file, file: 'thumbnail'),
            class: "img-responsive",
            alt: "#{title} of #{@generic_file.title.first}"
          )
        end
        concat content_tag :figcaption, "Download the file"
      end
    end
  end
end
