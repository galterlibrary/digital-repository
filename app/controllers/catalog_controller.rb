# -*- coding: utf-8 -*-
# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'blacklight_advanced_search'

# bl_advanced_search 1.2.4 is doing unitialized constant on these because we're calling ParseBasicQ directly
require 'parslet'
require 'parsing_nesting/tree'

class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include Sufia::Catalog

  # These before_filters apply the hydra access controls
  before_filter :enforce_show_permissions, only: :show
  # This applies appropriate access controls to all solr queries
  #CatalogController.search_params_logic += [
  #  :add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr]
  CatalogController.search_params_logic += [:add_advanced_parse_q_to_solr]

  before_filter do
    if current_user.present? &&
        (current_user.has_role?('admin') || current_user.has_role?('editor'))
      CatalogController.search_params_logic =
        CatalogController.search_params_logic - [
          :add_access_controls_to_solr_params]
    else
      CatalogController.search_params_logic =
        CatalogController.search_params_logic | [
          :add_access_controls_to_solr_params]
    end
  end

  skip_before_filter :default_html_head

  def index
    super
    all_collections_params = search_params_logic - [
      :only_generic_files_and_collections,
      :add_facet_fq_to_solr,
      :add_facetting_to_solr,
      :add_paging_to_solr,
      :add_group_config_to_solr,
      :add_facet_paging_to_solr
    ] + [:show_only_collections]
    (r, @user_collections) = search_results({}, all_collections_params)
  end

  def self.uploaded_field
    solr_name('date_uploaded', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('date_modified', :stored_sortable, type: :date)
  end

  def self.page_number_field
    solr_name('page_number_actual', :stored_sortable, type: :integer)
  end

  def self.title_field
    solr_name('label', :sortable)
  end

  configure_blacklight do |config|
    config.view.gallery.partials = [:index_header, :index]
    config.view.masonry.partials = [:index]

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10
    }

    # Specify which field to use in the tag cloud on the homepage.
    # To disable the tag cloud, comment out this line.
    config.tag_cloud_field_name = Solrizer.solr_name("tags", :facetable)

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_method = :sufia_thumbnail_tag

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name("resource_type", :facetable), label: "Resource Type", limit: 5
    config.add_facet_field solr_name("creator", :facetable), label: "Creator", limit: 5
    config.add_facet_field solr_name("tag", :facetable), label: "Keyword", limit: 5
    config.add_facet_field solr_name("tags", :facetable), label: "All Subjects", limit: 5
    config.add_facet_field solr_name("language", :facetable), label: "Language", limit: 5
    config.add_facet_field solr_name("based_near", :facetable), label: "Location", limit: 5
    config.add_facet_field solr_name("publisher", :facetable), label: "Publisher", limit: 5
    config.add_facet_field solr_name("file_format", :facetable), label: "File Format", limit: 5
    config.add_facet_field solr_name("rights", :facetable), label: "Rights Statement", limit: 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name("title", :stored_searchable), label: "Title", itemprop: 'name'
    config.add_index_field solr_name("description", :stored_searchable), label: "Description", itemprop: 'description'
    config.add_index_field solr_name("bibliographic_citation", :stored_searchable), label: "Bibliographic Citation", itemprop: 'bibliographic_citation'
    config.add_index_field solr_name("abstract", :stored_searchable), label: "Abstract", itemprop: 'abstract'
    config.add_index_field solr_name("tag", :stored_searchable), label: "Keyword", itemprop: 'keywords'
    config.add_index_field solr_name("subject", :stored_searchable), label: "Subject", itemprop: 'about'
    config.add_index_field solr_name("mesh", :stored_searchable), label: "Subject: MESH", itemprop: 'about'
    config.add_index_field solr_name("lcsh", :stored_searchable), label: "Subject: LCSH", itemprop: 'about'
    config.add_index_field solr_name("subject_geographic", :stored_searchable), label: "Subject: Geographic Name", itemprop: 'about'
    config.add_index_field solr_name("subject_name", :stored_searchable), label: "Subject: Name", itemprop: 'about'
    config.add_index_field solr_name("digital_origin", :stored_searchable), label: "Digital Origin", itemprop: 'digital_origin'
    config.add_index_field solr_name("creator", :stored_searchable), label: "Creator", itemprop: 'creator'
    config.add_index_field solr_name("contributor", :stored_searchable), label: "Contributor", itemprop: 'contributor'
    config.add_index_field solr_name("publisher", :stored_searchable), label: "Publisher", itemprop: 'publisher'
    config.add_index_field solr_name("page_number", :stored_searchable), label: "Page Number", itemprop: 'pageNumber'
    config.add_index_field solr_name("multi_page", :stored_searchable), label: "Multi Page", itemprop: 'multiPage'
    config.add_index_field solr_name("based_near", :stored_searchable), label: "Location", itemprop: 'contentLocation'
    config.add_index_field solr_name("language", :stored_searchable), label: "Language", itemprop: 'inLanguage'
    config.add_index_field solr_name("date_uploaded", :stored_searchable), label: "Date Uploaded", itemprop: 'datePublished'
    config.add_index_field solr_name("date_modified", :stored_searchable), label: "Date Modified", itemprop: 'dateModified'
    config.add_index_field solr_name("date_created", :stored_searchable), label: "Date Created", itemprop: 'dateCreated'
    config.add_index_field solr_name("rights", :stored_searchable), label: "Rights"
    config.add_index_field solr_name("resource_type", :stored_searchable), label: "Resource Type"
    config.add_index_field solr_name("format", :stored_searchable), label: "File Format"
    config.add_index_field solr_name("identifier", :stored_searchable), label: "Identifier"

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field solr_name("title", :stored_searchable), label: "Title"
    config.add_show_field solr_name("description", :stored_searchable), label: "Description"
    config.add_show_field solr_name("bibliographic_citation", :stored_searchable), label: "Bibliographic Citation"
    config.add_show_field solr_name("abstract", :stored_searchable), label: "Abstract"
    config.add_show_field solr_name("grants_and_funding", :stored_searchable), label: "Grants and Funding"
    config.add_show_field solr_name("acknowledgments", :stored_searchable), label: "Acknowledgments"
    config.add_show_field solr_name("doi", :stored_searchable), label: "DOI"
    config.add_show_field solr_name("ark", :stored_searchable), label: "ARK"
    config.add_show_field solr_name("tag", :stored_searchable), label: "Keyword"
    config.add_show_field solr_name("subject", :stored_searchable), label: "Subject"
    config.add_show_field solr_name("mesh", :stored_searchable), label: "Subject: MESH"
    config.add_show_field solr_name("lcsh", :stored_searchable), label: "Subject: LCSH"
    config.add_show_field solr_name("subject_geographic", :stored_searchable), label: "Subject: Geographic Name"
    config.add_show_field solr_name("subject_name", :stored_searchable), label: "Subject: Name"
    config.add_show_field solr_name("digital_origin", :stored_searchable), label: "Digital Origin"
    config.add_show_field solr_name("creator", :stored_searchable), label: "Creator"
    config.add_show_field solr_name("contributor", :stored_searchable), label: "Contributor"
    config.add_show_field solr_name("publisher", :stored_searchable), label: "Publisher"
    config.add_show_field solr_name("page_number", :stored_searchable), label: "Page Number"
    config.add_show_field solr_name("multi_page", :stored_searchable), label: "Multi-Page?"
    config.add_show_field solr_name("based_near", :stored_searchable), label: "Location"
    config.add_show_field solr_name("language", :stored_searchable), label: "Language"
    config.add_show_field solr_name("date_uploaded", :stored_searchable), label: "Date Uploaded"
    config.add_show_field solr_name("date_modified", :stored_searchable), label: "Date Modified"
    config.add_show_field solr_name("date_created", :stored_searchable), label: "Date Created"
    config.add_show_field solr_name("rights", :stored_searchable), label: "Rights"
    config.add_show_field solr_name("resource_type", :stored_searchable), label: "Resource Type"
    config.add_show_field solr_name("format", :stored_searchable), label: "File Format"
    config.add_show_field solr_name("identifier", :stored_searchable), label: "Identifier"

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: false) do |field|
      all_names = config.show_fields.values.map{|val| val.field}.join(" ")
      title_name = solr_name("title", :stored_searchable)
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim all_text_timv",
        pf: "#{title_name}"
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { :"spellcheck.dictionary" => "contributor" }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = solr_name("contributor", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      field.solr_parameters = { :"spellcheck.dictionary" => "creator" }
      solr_name = solr_name("creator", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "title"
      }
      solr_name = solr_name("title", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('abstract') do |field|
      field.label = "Abstract"
      field.solr_parameters = {
        :"spellcheck.dictionary" => "abstract"
      }
      solr_name = solr_name("abstract", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('bibliographic_citation') do |field|
      field.label = "Bibliographic Citation"
      field.solr_parameters = {
        :"spellcheck.dictionary" => "bibliographic_citation"
      }
      solr_name = solr_name("bibliographic_citation", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = "Description"
      field.solr_parameters = {
        :"spellcheck.dictionary" => "description"
      }
      solr_name = solr_name("description", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "publisher"
      }
      solr_name = solr_name("publisher", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('page_number') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "page_number"
      }
      solr_name = solr_name("page_number", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('muti_page') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "muti_page"
      }
      solr_name = solr_name("muti_page", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "date_created"
      }
      solr_name = solr_name("created", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "subject"
      }
      solr_name = solr_name("subject", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('mesh') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "mesh"
      }
      solr_name = solr_name("mesh", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('lcsh') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "lcsh"
      }
      solr_name = solr_name("lcsh", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject_geographic') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "subject_geographic"
      }
      solr_name = solr_name("subject_geographic", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject_name') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "subject_name"
      }
      solr_name = solr_name("subject_name", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('digital_origin') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "digital_origin"
      }
      solr_name = solr_name("digital_origin", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "language"
      }
      solr_name = solr_name("language", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "resource_type"
      }
      solr_name = solr_name("resource_type", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "format"
      }
      solr_name = solr_name("format", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "identifier"
      }
      solr_name = solr_name("id", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('based_near') do |field|
      field.label = "Location"
      field.solr_parameters = {
        :"spellcheck.dictionary" => "based_near"
      }
      solr_name = solr_name("based_near", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('tag') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "tag"
      }
      solr_name = solr_name("tag", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = solr_name("depositor", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights') do |field|
      solr_name = solr_name("rights", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"
    config.add_sort_field "#{page_number_field} desc", label: "page number\u25BC"
    config.add_sort_field "#{page_number_field} asc", label: "page number\u25B2"
    config.add_sort_field "#{title_field} desc", label: "title\u25BC"
    config.add_sort_field "#{title_field} asc", label: "title\u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

end
