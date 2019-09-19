Sufia.config do |config|
  # Sufia can integrate with Zotero's Arkivo service for automatic deposit
  # of Zotero-managed research items.
  # Defaults to false.  See README for more info
  config.arkivo_api = true


  config.fits_to_desc_mapping= {
    file_title: :title,
    file_author: :creator
  }

  config.max_days_between_audits = 7

  config.max_notifications_for_dashboard = 5

  config.cc_licenses = {
    'Click to select...' => '',
    'Attribution 4.0 International' => 'http://creativecommons.org/licenses/by/4.0/',
    'Attribution 3.0 United States' => 'http://creativecommons.org/licenses/by/3.0/us/',
    'Attribution-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-sa/3.0/us/',
    'Attribution-NonCommercial 3.0 United States' => 'http://creativecommons.org/licenses/by-nc/3.0/us/',
    'Attribution-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nd/3.0/us/',
    'Attribution-NonCommercial-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-nd/3.0/us/',
    'Attribution-NonCommercial-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-sa/3.0/us/',
    'Public Domain Mark 1.0' => 'http://creativecommons.org/publicdomain/mark/1.0/',
    'CC0 1.0 Universal' => 'http://creativecommons.org/publicdomain/zero/1.0/',
    'The MIT License (MIT)' => 'https://opensource.org/licenses/MIT',
    'All rights reserved' => 'All rights reserved'
  }

  config.cc_licenses_reverse = Hash[*config.cc_licenses.to_a.flatten.reverse]

  config.resource_types = {
    "Abbreviations"=>"Abbreviations",
    "Abstracts"=>"Abstracts",
    "Academic Dissertations"=>"Academic Dissertations",
    "Account Books"=>"Account Books",
    "Addresses"=>"Addresses",
    "Advertisements"=>"Advertisements",
    "Almanacs"=>"Almanacs",
    "Anecdotes"=>"Anecdotes",
    "Animation"=>"Animation",
    "Annual Reports"=>"Annual Reports",
    "Aphorisms and Proverbs"=>"Aphorisms and Proverbs",
    "Architectural Drawings"=>"Architectural Drawings",
    "Article"=>"Article",
    "Atlases"=>"Atlases",
    "Audio Visual Document" => "Audio Visual Document",
    "Autobiography"=>"Autobiography",
    "Bibliography"=>"Bibliography",
    "Biobibliography"=>"Biobibliography",
    "Biography"=>"Biography",
    "Blogs" => "Blogs",
    "Book Illustrations"=>"Book Illustrations",
    "Book Reviews"=>"Book Reviews",
    "Book"=>"Book",
    "Bookplates"=>"Bookplates",
    "Broadsides"=>"Broadsides",
    "Capstone Project"=>"Capstone Project",
    "Caricatures"=>"Caricatures",
    "Cartoons"=>"Cartoons",
    "Case Reports"=>"Case Reports",
    "Catalogs"=>"Catalogs",
    "Charts"=>"Charts",
    "Chronology"=>"Chronology",
    "Classical Article"=>"Classical Article",
    "Clinical Conference"=>"Clinical Conference",
    "Clinical Study" => "Clinical Study",
    "Clinical Trial"=>"Clinical Trial",
    "Clinical Trial, Phase I"=>"Clinical Trial, Phase I",
    "Clinical Trial, Phase II"=>"Clinical Trial, Phase II",
    "Clinical Trial, Phase III"=>"Clinical Trial, Phase III",
    "Clinical Trial, Phase IV"=>"Clinical Trial, Phase IV",
    "Collected Correspondence"=>"Collected Correspondence",
    "Collected Works"=>"Collected Works",
    "Collections"=>"Collections",
    "Comment"=>"Comment",
    "Comparative Study"=>"Comparative Study",
    "Conference Proceeding"=>"Conference Proceeding",
    "Congresses"=>"Congresses",
    "Consensus Development Conference"=>"Consensus Development Conference",
    "Consensus Development Conference, NIH"=>"Consensus Development Conference, NIH",
    "Controlled Clinical Trial"=>"Controlled Clinical Trial",
    "Cookbooks"=>"Cookbooks",
    "Corrected and Republished Article"=>"Corrected and Republished Article",
    "Database"=>"Database",
    "Dataset" => "Dataset",
    "Diaries"=>"Diaries",
    "Dictionary"=>"Dictionary",
    "Directory"=>"Directory",
    "Dissertation"=>"Dissertation",
    "Drawings"=>"Drawings",
    "Duplicate Publication"=>"Duplicate Publication",
    "Editorial Article"=>"Editorial Article",
    "Editorial"=>"Editorial",
    "Electronic Supplementary Materials"=>"Electronic Supplementary Materials",
    "Encyclopedias"=>"Encyclopedias",
    "English Abstract"=>"English Abstract",
    "Ephemera"=>"Ephemera",
    "Essays"=>"Essays",
    "Eulogies"=>"Eulogies",
    "Evaluation Studies"=>"Evaluation Studies",
    "Examination Questions"=>"Examination Questions",
    "Exhibitions"=>"Exhibitions",
    "Festschrift"=>"Festschrift",
    "Fictional Works"=>"Fictional Works",
    "Forms"=>"Forms",
    "Formularies"=>"Formularies",
    "Funeral Sermons"=>"Funeral Sermons",
    "Government Publications"=>"Government Publications",
    "Graphic Novels" => "Graphic Novels",
    "Guidebooks"=>"Guidebooks",
    "Guideline"=>"Guideline",
    "Handbooks"=>"Handbooks",
    "Herbals"=>"Herbals",
    "Historical Article"=>"Historical Article",
    "Humor"=>"Humor",
    "Image"=>"Image",
    "Incunabula"=>"Incunabula",
    "Indexes"=>"Indexes",
    "Interview"=>"Interview",
    "Introductory Journal Article"=>"Introductory Journal Article",
    "Journal Article"=>"Journal Article",
    "Journal"=>"Journal",
    "Juvenile Literature"=>"Juvenile Literature",
    "Laboratory Manuals"=>"Laboratory Manuals",
    "Lecture Notes"=>"Lecture Notes",
    "Lectures"=>"Lectures",
    "Legal Cases"=>"Legal Cases",
    "Legislation"=>"Legislation",
    "Letter"=>"Letter",
    "Manuscript"=>"Manuscript",
    "Maps"=>"Maps",
    "Masters Thesis"=>"Masters Thesis",
    "Meeting Abstracts"=>"Meeting Abstracts",
    "Meta-Analysis"=>"Meta-Analysis",
    "Monograph"=>"Monograph",
    "Multicenter Study"=>"Multicenter Study",
    "News"=>"News",
    "Newspaper Article"=>"Newspaper Article",
    "Nurses' Instruction"=>"Nurses' Instruction",
    "Observational Study"=>"Observational Study",
    "Other"=>"Other",
    "Outlines"=>"Outlines",
    "Overall"=>"Overall",
    "Part of Book"=>"Part of Book",
    "Patents"=>"Patents",
    "Patient Education Handout"=>"Patient Education Handout",
    "Periodical Index"=>"Periodical Index",
    "Periodicals"=>"Periodicals",
    "Personal Narratives"=>"Personal Narratives",
    "Pharmacopoeias"=>"Pharmacopoeias",
    "Photographs"=>"Photographs",
    "Phrases"=>"Phrases",
    "Pictorial Works"=>"Pictorial Works",
    "Poetry"=>"Poetry",
    "Popular Works"=>"Popular Works",
    "Portraits"=>"Portraits",
    "Postcards"=>"Postcards",
    "Poster"=>"Poster",
    "Practice Guideline"=>"Practice Guideline",
    "Pragmatic Clinical Trial"=>"Pragmatic Clinical Trial",
    "Presentation"=>"Presentation",
    "Price Lists"=>"Price Lists",
    "Problems and Exercises"=>"Problems and Exercises",
    "Programmed Instruction"=>"Programmed Instruction",
    "Programs"=>"Programs",
    "Project"=>"Project",
    "Prospectuses"=>"Prospectuses",
    "Public service announcements" => "Public service announcements",
    "Publication Components"=>"Publication Components",
    "Publication Formats"=>"Publication Formats",
    "Published Erratum"=>"Published Erratum",
    "Randomized Controlled Trial"=>"Randomized Controlled Trial",
    "Report"=>"Report",
    "Research Design"=>"Research Design",
    "Research Paper"=>"Research Paper",
    "Research Support, American Recovery and Reinvestment Act"=> "Research Support, American Recovery and Reinvestment Act",
    "Research Support, N.I.H., Extramural"=>"Research Support, N.I.H., Extramural",
    "Research Support, N.I.H., Intramural"=>"Research Support, N.I.H., Intramural",
    "Research Support, Non-U.S. Gov't"=>"Research Support, Non-U.S. Gov't",
    "Research Support, U.S. Gov't, Non-P.H.S."=> "Research Support, U.S. Gov't, Non-P.H.S.",
    "Research Support, U.S. Gov't, P.H.S."=>"Research Support, U.S. Gov't, P.H.S.",
    "Research Support, U.S. Government"=>"Research Support, U.S. Government",
    "Resource Guides"=>"Resource Guides",
    "Retracted Publication"=>"Retracted Publication",
    "Retraction of Publication"=>"Retraction of Publication",
    "Retraction"=>"Retraction",
    "Review"=>"Review",
    "Scientific Integrity Review"=>"Scientific Integrity Review",
    "Sermons"=>"Sermons",
    "Software or Program Code"=>"Software or Program Code",
    "Speech"=>"Speech",
    "Statistics"=>"Statistics",
    "Study Characteristics"=>"Study Characteristics",
    "Support of Research"=>"Support of Research",
    "Tables"=>"Tables",
    "Technical Report"=>"Technical Report",
    "Terminology"=>"Terminology",
    "Textbooks"=>"Textbooks",
    "Twin Study"=>"Twin Study",
    "Union Lists"=>"Union Lists",
    "Unpublished Works"=>"Unpublished Works",
    "Validation Studies"=>"Validation Studies",
  }

  config.resource_types_to_schema = {
    "Abbreviations"=>"http://id.nlm.nih.gov/mesh/D020463",
    "Abstracts"=>"http://id.nlm.nih.gov/mesh/D020504",
    "Academic Dissertations"=>"http://id.nlm.nih.gov/mesh/D019478",
    "Account Books"=>"http://id.nlm.nih.gov/mesh/D019479",
    "Addresses"=>"http://id.nlm.nih.gov/mesh/D019484",
    "Advertisements"=>"http://id.nlm.nih.gov/mesh/D019480",
    "Almanacs"=>"http://id.nlm.nih.gov/mesh/D019482",
    "Anecdotes"=>"http://id.nlm.nih.gov/mesh/D020465",
    "Animation"=>"http://id.nlm.nih.gov/mesh/D019486",
    "Annual Reports"=>"http://id.nlm.nih.gov/mesh/D019487",
    "Aphorisms and Proverbs"=>"http://id.nlm.nih.gov/mesh/D054519",
    "Architectural Drawings"=>"http://id.nlm.nih.gov/mesh/D019488",
    "Article"=>"http://schema.org/Article",
    "Atlases"=>"http://id.nlm.nih.gov/mesh/D020466",
    "Audio Visual Document" => "http://purl.org/ontology/bibo/AudioVisualDocument",
    "Autobiography"=>"http://id.nlm.nih.gov/mesh/D020493",
    "Bibliography"=>"http://id.nlm.nih.gov/mesh/D016417",
    "Biobibliography"=>"http://id.nlm.nih.gov/mesh/D020467",
    "Biography"=>"http://id.nlm.nih.gov/mesh/D019215",
    "Blogs" => "https://id.nlm.nih.gov/mesh/D000069520",
    "Book Illustrations"=>"http://id.nlm.nih.gov/mesh/D019489",
    "Book Reviews"=>"http://id.nlm.nih.gov/mesh/D022921",
    "Book"=>"http://schema.org/Book",
    "Bookplates"=>"http://id.nlm.nih.gov/mesh/D019491",
    "Broadsides"=>"http://id.nlm.nih.gov/mesh/D019490",
    "Capstone Project"=>"http://schema.org/CreativeWork",
    "Caricatures"=>"http://id.nlm.nih.gov/mesh/D019492",
    "Cartoons"=>"http://id.nlm.nih.gov/mesh/D019493",
    "Case Reports"=>"http://id.nlm.nih.gov/mesh/D002363",
    "Catalogs"=>"http://id.nlm.nih.gov/mesh/D019494",
    "Charts"=>"http://id.nlm.nih.gov/mesh/D020468",
    "Chronology"=>"http://id.nlm.nih.gov/mesh/D020469",
    "Classical Article"=>"http://id.nlm.nih.gov/mesh/D016419",
    "Clinical Conference"=>"http://id.nlm.nih.gov/mesh/D016429",
    "Clinical Study" => "https://id.nlm.nih.gov/mesh/D000068397",
    "Clinical Trial"=> "http://id.nlm.nih.gov/mesh/D016430",
    "Clinical Trial, Phase I"=> "http://id.nlm.nih.gov/mesh/D017426",
    "Clinical Trial, Phase II"=> "http://id.nlm.nih.gov/mesh/D017427",
    "Clinical Trial, Phase III"=> "http://id.nlm.nih.gov/mesh/D017428",
    "Clinical Trial, Phase IV"=> "http://id.nlm.nih.gov/mesh/D017429",
    "Collected Correspondence"=>"http://id.nlm.nih.gov/mesh/D020505",
    "Collected Works"=>"http://id.nlm.nih.gov/mesh/D020470",
    "Collections"=>"http://id.nlm.nih.gov/mesh/D020471",
    "Comment"=>"http://id.nlm.nih.gov/mesh/D016420",
    "Comparative Study"=>"http://id.nlm.nih.gov/mesh/D003160",
    "Conference Proceeding"=>"http://schema.org/ScholarlyArticle",
    "Congresses"=>"http://id.nlm.nih.gov/mesh/D016423",
    "Consensus Development Conference"=>"http://id.nlm.nih.gov/mesh/D016446",
    "Consensus Development Conference, NIH"=>"http://id.nlm.nih.gov/mesh/D016447",
    "Controlled Clinical Trial"=>"http://id.nlm.nih.gov/mesh/D018848",
    "Cookbooks"=>"http://id.nlm.nih.gov/mesh/D055823",
    "Corrected and Republished Article"=>"http://id.nlm.nih.gov/mesh/D016439",
    "Database"=>"http://id.nlm.nih.gov/mesh/D019991",
    "Dataset" => "http://schema.org/Dataset",
    "Diaries"=>"http://id.nlm.nih.gov/mesh/D019497",
    "Dictionary"=>"http://id.nlm.nih.gov/mesh/D016437",
    "Directory"=>"http://id.nlm.nih.gov/mesh/D016435",
    "Dissertation"=>"http://schema.org/ScholarlyArticle",
    "Drawings"=>"http://id.nlm.nih.gov/mesh/D020472",
    "Duplicate Publication"=>"http://id.nlm.nih.gov/mesh/D016438",
    "Editorial Article"=> "http://vivoweb.org/files/vivo-isf-public-1.6.owl#Editorial Article",
    "Editorial"=>"http://id.nlm.nih.gov/mesh/D016421",
    "Electronic Supplementary Materials"=>"http://id.nlm.nih.gov/mesh/D058537",
    "Encyclopedias"=>"http://id.nlm.nih.gov/mesh/D019500",
    "English Abstract"=>"http://id.nlm.nih.gov/mesh/D004740",
    "Ephemera"=>"http://id.nlm.nih.gov/mesh/D019502",
    "Essays"=>"http://id.nlm.nih.gov/mesh/D020474",
    "Eulogies"=>"http://id.nlm.nih.gov/mesh/D019504",
    "Evaluation Studies"=>"http://id.nlm.nih.gov/mesh/D023362",
    "Examination Questions"=>"http://id.nlm.nih.gov/mesh/D020475",
    "Exhibitions"=>"http://id.nlm.nih.gov/mesh/D020476",
    "Festschrift"=>"http://id.nlm.nih.gov/mesh/D016221",
    "Fictional Works"=>"http://id.nlm.nih.gov/mesh/D022922",
    "Forms"=>"http://id.nlm.nih.gov/mesh/D020478",
    "Formularies"=>"http://id.nlm.nih.gov/mesh/D055824",
    "Funeral Sermons"=>"http://id.nlm.nih.gov/mesh/D019505",
    "Government Publications"=>"http://id.nlm.nih.gov/mesh/D022903",
    "Graphic Novels" => "https://id.nlm.nih.gov/mesh/D000068036",
    "Guidebooks"=>"http://id.nlm.nih.gov/mesh/D019508",
    "Guideline"=>"http://id.nlm.nih.gov/mesh/D016431",
    "Handbooks"=>"http://id.nlm.nih.gov/mesh/D020479",
    "Herbals"=>"http://id.nlm.nih.gov/mesh/D019509",
    "Historical Article"=>"http://id.nlm.nih.gov/mesh/D016456",
    "Humor"=>"http://id.nlm.nih.gov/mesh/D020480",
    "Image"=>"http://schema.org/ImageObject",
    "Incunabula"=>"http://id.nlm.nih.gov/mesh/D057213",
    "Indexes"=>"http://id.nlm.nih.gov/mesh/D020481",
    "Interview"=>"http://id.nlm.nih.gov/mesh/D017203",
    "Introductory Journal Article"=>"http://id.nlm.nih.gov/mesh/D054711",
    "Journal Article"=>"http://id.nlm.nih.gov/mesh/D016428",
    "Journal"=>"http://schema.org/CreativeWork",
    "Juvenile Literature"=>"http://id.nlm.nih.gov/mesh/D020482",
    "Laboratory Manuals"=>"http://id.nlm.nih.gov/mesh/D020484",
    "Lecture Notes"=>"http://id.nlm.nih.gov/mesh/D019528",
    "Lectures"=>"http://id.nlm.nih.gov/mesh/D019531",
    "Legal Cases"=>"http://id.nlm.nih.gov/mesh/D016418",
    "Legislation"=>"http://id.nlm.nih.gov/mesh/D020485",
    "Letter"=>"http://id.nlm.nih.gov/mesh/D016422",
    "Manuscript"=>"http://purl.org/ontology/bibo/Manuscript",
    "Maps"=>"http://id.nlm.nih.gov/mesh/D019532",
    "Masters Thesis"=>"http://schema.org/ScholarlyArticle",
    "Meeting Abstracts"=>"http://id.nlm.nih.gov/mesh/D016416",
    "Meta-Analysis"=>"http://id.nlm.nih.gov/mesh/D017418",
    "Monograph"=>"http://id.nlm.nih.gov/mesh/D016467",
    "Multicenter Study"=>"http://id.nlm.nih.gov/mesh/D016448",
    "News"=>"http://id.nlm.nih.gov/mesh/D016433",
    "Newspaper Article"=>"http://id.nlm.nih.gov/mesh/D018431",
    "Nurses' Instruction"=>"http://id.nlm.nih.gov/mesh/D020488",
    "Observational Study"=>"http://id.nlm.nih.gov/mesh/D064888",
    "Other"=>"http://schema.org/CreativeWork",
    "Outlines"=>"http://id.nlm.nih.gov/mesh/D020489",
    "Overall"=>"http://id.nlm.nih.gov/mesh/D016424",
    "Part of Book"=>"http://schema.org/Book",
    "Patents"=>"http://id.nlm.nih.gov/mesh/D020490",
    "Patient Education Handout"=>"http://id.nlm.nih.gov/mesh/D029282",
    "Periodical Index"=>"http://id.nlm.nih.gov/mesh/D016453",
    "Periodicals"=>"http://id.nlm.nih.gov/mesh/D020492",
    "Personal Narratives"=>"http://id.nlm.nih.gov/mesh/D062210",
    "Pharmacopoeias"=>"http://id.nlm.nih.gov/mesh/D019539",
    "Photographs"=>"http://id.nlm.nih.gov/mesh/D059036",
    "Phrases"=>"http://id.nlm.nih.gov/mesh/D020494",
    "Pictorial Works"=>"http://id.nlm.nih.gov/mesh/D020495",
    "Poetry"=>"http://id.nlm.nih.gov/mesh/D055821",
    "Popular Works"=>"http://id.nlm.nih.gov/mesh/D020496",
    "Portraits"=>"http://id.nlm.nih.gov/mesh/D019477",
    "Postcards"=>"http://id.nlm.nih.gov/mesh/D056571",
    "Poster"=>"http://schema.org/CreativeWork",
    "Practice Guideline"=>"http://id.nlm.nih.gov/mesh/D017065",
    "Pragmatic Clinical Trial"=>"http://id.nlm.nih.gov/mesh/D065007",
    "Presentation"=>"http://schema.org/CreativeWork",
    "Price Lists"=>"http://id.nlm.nih.gov/mesh/D019525",
    "Problems and Exercises"=>"http://id.nlm.nih.gov/mesh/D020497",
    "Programmed Instruction"=>"http://id.nlm.nih.gov/mesh/D020498",
    "Programs"=>"http://id.nlm.nih.gov/mesh/D019542",
    "Project"=>"http://schema.org/CreativeWork",
    "Prospectuses"=>"http://id.nlm.nih.gov/mesh/D019527",
    "Public service announcements" => "https://id.nlm.nih.gov/mesh/D066309",
    "Publication Components"=>"http://id.nlm.nih.gov/mesh/D052181",
    "Publication Formats"=>"http://id.nlm.nih.gov/mesh/D052180",
    "Published Erratum"=>"http://id.nlm.nih.gov/mesh/D016425",
    "Randomized Controlled Trial"=>"http://id.nlm.nih.gov/mesh/D016449",
    "Report"=>"http://schema.org/CreativeWork",
    "Research Desgin"=>"https://id.nlm.nih.gov/mesh/D012107",
    "Research Paper"=>"http://schema.org/ScholarlyArticle",
    "Research Support, American Recovery and Reinvestment Act"=> "http://id.nlm.nih.gov/mesh/D057666",
    "Research Support, N.I.H., Extramural"=>"http://id.nlm.nih.gov/mesh/D052061",
    "Research Support, N.I.H., Intramural"=>"http://id.nlm.nih.gov/mesh/D052060",
    "Research Support, Non-U.S. Gov't"=>"http://id.nlm.nih.gov/mesh/D013485",
    "Research Support, U.S. Gov't, Non-P.H.S."=>"http://id.nlm.nih.gov/mesh/D013486",
    "Research Support, U.S. Gov't, P.H.S."=>"http://id.nlm.nih.gov/mesh/D013487",
    "Research Support, U.S. Government"=>"http://id.nlm.nih.gov/mesh/D057689",
    "Resource Guides"=>"http://id.nlm.nih.gov/mesh/D020507",
    "Retracted Publication"=>"http://id.nlm.nih.gov/mesh/D016441",
    "Retraction of Publication"=>"http://id.nlm.nih.gov/mesh/D016440",
    "Retraction"=>"http://purl.org/spar/fabio/Retraction",
    "Review"=>"http://id.nlm.nih.gov/mesh/D016454",
    "Scientific Integrity Review"=>"http://id.nlm.nih.gov/mesh/D016426",
    "Sermons"=>"http://id.nlm.nih.gov/mesh/D019523",
    "Software or Program Code"=>"http://schema.org/Code",
    "Speech"=>"http://vivoweb.org/files/vivo-isf-public-1.6.owl#Speech",
    "Statistics"=>"http://id.nlm.nih.gov/mesh/D020500",
    "Study Characteristics"=>"http://id.nlm.nih.gov/mesh/D052182",
    "Support of Research"=>"http://id.nlm.nih.gov/mesh/D052288",
    "Tables"=>"http://id.nlm.nih.gov/mesh/D020501",
    "Technical Report"=>"http://id.nlm.nih.gov/mesh/D016427",
    "Terminology"=>"http://id.nlm.nih.gov/mesh/D020502",
    "Textbooks"=>"http://id.nlm.nih.gov/mesh/D022923",
    "Twin Study"=>"http://id.nlm.nih.gov/mesh/D018486",
    "Union Lists"=>"http://id.nlm.nih.gov/mesh/D020503",
    "Unpublished Works"=>"http://id.nlm.nih.gov/mesh/D022902",
    "Validation Studies"=>"http://id.nlm.nih.gov/mesh/D023361",
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
  if Rails.env.production? || Rails.env.staging?
    # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
    config.analytics = true

    # Specify a Google Analytics tracking ID to gather usage statistics
    config.google_analytics_id = ENV['GOOGLE_ANALYTICS_ID']

    # Specify a date you wish to start collecting Google Analytic statistics for.
    config.analytic_start_date = DateTime.new(2015,10,1)
  end

  config.geonames_username = 'galterlibrary'
  # Enables a link to the citations page for a generic_file.
  # Default is false
  config.citations = true
  # Enables a select menu on the batch upload page to select a collection into which to add newly uploaded files.
  # Default is false
  config.upload_to_collection = true

  # How many times to retry to acquire the lock before raising UnableToAcquireLockError
  # Default is 600ms
  # config.lock_retry_count = 600 # Up to 2 minutes of trying at intervals up to 200ms

  # How long to hold the lock in milliseconds
  # Default is 60_000ms
  # config.lock_time_to_live = 60_000 # milliseconds

  # Maximum wait time in milliseconds before retrying. Wait time is a random value between 0 and retry_delay.
  # Default is 200ms
  # config.lock_retry_delay = 200 # milliseconds

  # Add a collection facet to search results.  Possible values are...
  #   nil (default) - do not include collection facet
  #   :user - show for logged in users
  #   :public - show for everyone (e.g. logged in and non-logged in users)
  config.collection_facet = :public
# Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  config.temp_file_base = ENV['TMP_DIR_PATH']

  # Specify the form of hostpath to be used in Endnote exports
  config.persistent_hostpath = "https://#{ENV['FULL_HOSTNAME']}/files/"

  # If you have ffmpeg installed and want to transcode audio and video uncomment this line
  config.enable_ffmpeg = true

  # Sufia uses NOIDs for files and collections instead of Fedora UUIDs
  # where NOID = 10-character string and UUID = 32-character string w/ hyphens
  config.enable_noids = false

  # Specify a different template for your repository's NOID IDs
  # config.noid_template = ".reeddeeddk"

  # Specify the prefix for Redis keys:
  config.redis_namespace = "sufia"

  # Specify the path to the file characterization tool:
  config.fits_path = ENV['FITS_PATH'] || ENV['FITS_PATH_GLOBAL']

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

  # Contact Email
  config.contact_email = ENV['SERVER_ADMIN_EMAIL']
  config.from_email = 'ghsl-bogus@northwestern.edu'
end

Date::DATE_FORMATS[:standard] = "%m/%d/%Y"
