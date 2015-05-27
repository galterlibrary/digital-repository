Sufia.config do |config|

  config.fits_to_desc_mapping= {
    file_title: :title,
    file_author: :creator
  }

  config.max_days_between_audits = 7

  config.max_notifications_for_dashboard = 5

  config.cc_licenses = {
    'Attribution 3.0 United States' => 'http://creativecommons.org/licenses/by/3.0/us/',
    'Attribution-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-sa/3.0/us/',
    'Attribution-NonCommercial 3.0 United States' => 'http://creativecommons.org/licenses/by-nc/3.0/us/',
    'Attribution-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nd/3.0/us/',
    'Attribution-NonCommercial-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-nd/3.0/us/',
    'Attribution-NonCommercial-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-sa/3.0/us/',
    'Public Domain Mark 1.0' => 'http://creativecommons.org/publicdomain/mark/1.0/',
    'CC0 1.0 Universal' => 'http://creativecommons.org/publicdomain/zero/1.0/',
    'All rights reserved' => 'All rights reserved'
  }

  config.cc_licenses_reverse = Hash[*config.cc_licenses.to_a.flatten.reverse]

  config.resource_types = {

    "Article" => "Article",
    "Audio" => "Audio",
    "Bibliography" => "Bibliography",
    "Biography" => "Biography",
    "Book" => "Book",
    "Capstone Project" => "Capstone Project",
    "Case Reports" => "Case Reports",
    "Clinical Trial" => "Clinical Trial",
    "Clinical Trial, Phase I" => "Clinical Trial, Phase I",
    "Clinical Trial, Phase II" => "Clinical Trial, Phase II",
    "Clinical Trial, Phase III" => "Clinical Trial, Phase III",
    "Clinical Trial, Phase IV" => "Clinical Trial, Phase IV",
    "Comparative Study" => "Comparative Study",
    "Conference Proceeding" => "Conference Proceeding",
    "Controlled Clinical Trial" => "Controlled Clinical Trial",
    "Dataset" => "Dataset",
    "Dissertation" => "Dissertation",
    "Editorial Article" => "Editorial Article",
    "Evaluation Study" => "Evaluation Study",
    "Image" => "Image",
    "Journal" => "Journal",
    "Lectures" => "Lectures",
    "Manuscript" => "Manuscript",
    "Map or Cartographic Material" => "Map or Cartographic Material",
    "Masters Thesis" => "Masters Thesis",
    "Newspaper Article" => "Newspaper Article",
    "Other" => "Other",
    "Part of Book" => "Part of Book",
    "Poster" => "Poster",
    "Presentation" => "Presentation",
    "Project" => "Project",
    "Report" => "Report",
    "Research Paper" => "Research Paper",
    "Software or Program Code" => "Software or Program Code",
    "Speech" => "Speech",
    "Technical Report" => "Technical Report",
    "Video" => "Video"
  }

  config.resource_types_to_schema = {
    "Article" => "http://schema.org/Article",
    "Autobiography" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Autobiography",
    "Audio" => "http://schema.org/AudioObject",
    "Bibliography" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Bibliography",
    "Biography" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Biography",
    "Book" => "http://schema.org/Book",
    "Capstone Project" => "http://schema.org/CreativeWork",
    "Case Reports" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Case Reports",
    "Clinical Trial" => "http://vivoweb.org/files/vivo-isf-public-1.6.owl#Clinical Trial",
    "Clinical Trial, Phase I" => "http://vivoweb.org/files/vivo-isf-public-1.6.owl#Clinical Trial, Phase I",
    "Clinical Trial, Phase II" => "http://vivoweb.org/files/vivo-isf-public-1.6.owl#Clinical Trial, Phase II",
    "Clinical Trial, Phase III" => "http://vivoweb.org/files/vivo-isf-public-1.6.owl#Clinical Trial, Phase III",
    "Clinical Trial, Phase IV" => "http://vivoweb.org/files/vivo-isf-public-1.6.owl#Clinical Trial, Phase IV",
    "Comparative Study" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Comparative Study",
    "Conference Proceeding" => "http://schema.org/ScholarlyArticle",
    "Controlled Clinical Trial" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Controlled Clinical Trial",
    "Dataset" => "http://schema.org/Dataset",
    "Dissertation" => "http://schema.org/ScholarlyArticle",
    "Editorial Article" => "http://vivoweb.org/files/vivo-isf-public-1.6.owl#Editorial Article",
    "Evaluation Study" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Evaluation Study",
    "Image" => "http://schema.org/ImageObject",
    "Journal" => "http://schema.org/CreativeWork",
    "Lectures" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Lectures",
    "Manuscript" => "http://purl.org/ontology/bibo/Manuscript",
    "Map or Cartographic Material" => "http://schema.org/Map",
    "Masters Thesis" => "http://schema.org/ScholarlyArticle",
    "Newspaper Article" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Newspaper Article",
    "Other" => "http://schema.org/CreativeWork",
    "Part of Book" => "http://schema.org/Book",
    "Poster" => "http://schema.org/CreativeWork",
    "Presentation" => "http://schema.org/CreativeWork",
    "Project" => "http://schema.org/CreativeWork",
    "Report" => "http://schema.org/CreativeWork",
    "Research Paper" => "http://schema.org/ScholarlyArticle",
    "Software or Program Code" => "http://schema.org/Code",
    "Speech" => "http://vivoweb.org/files/vivo-isf-public-1.6.owl#Speech",
    "Technical Report" => "https://github.com/vioil/ontology_extensions/blob/master/VlocalVI.rdf#Technical Report",
    "Video" => "http://schema.org/VideoObject"
  }

  config.permission_levels = {
    "Choose Access"=>"none",
    "View/Download" => "read",
    "Edit" => "edit"
  }

  config.owner_permission_levels = {
    "Edit" => "edit"
  }

  config.queue = Sufia::Resque::Queue

  # Enable displaying usage statistics in the UI
  # Defaults to FALSE
  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
  config.analytics = false

  # Specify a Google Analytics tracking ID to gather usage statistics
  # config.google_analytics_id = 'UA-99999999-1'

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  # config.temp_file_base = '/home/developer1'

  # Specify the form of hostpath to be used in Endnote exports
  # config.persistent_hostpath = 'http://localhost/files/'

  # If you have ffmpeg installed and want to transcode audio and video uncomment this line
  config.enable_ffmpeg = true

  # Sufia uses NOIDs for files and collections instead of Fedora UUIDs
  # where NOID = 10-character string and UUID = 32-character string w/ hyphens
  # config.enable_noids = true

  # Specify a different template for your repository's NOID IDs
  # config.noid_template = ".reeddeeddk"

  # Specify the prefix for Redis keys:
  config.redis_namespace = "sufia"

  # Specify the path to the file characterization tool:
  config.fits_path = "/home/deploy/fits-0.8.4/fits.sh"

  # Specify how many seconds back from the current time that we should show by default of the user's activity on the user's dashboard
  # config.activity_to_show_default_seconds_since_now = 24*60*60

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # If browse-everything has been configured, load the configs.  Otherwise, set to nil.
  begin
    if defined? BrowseEverything
      config.browse_everything = BrowseEverything.config
    else
      Rails.logger.warn "BrowseEverything is not installed"
    end
  rescue Errno::ENOENT
    config.browse_everything = nil
  end

  #config.enable_local_ingest = true

end

Date::DATE_FORMATS[:standard] = "%m/%d/%Y"
