require 'iiif/presentation'

class IiifApisController < ApplicationController
  before_filter :authorize_action, :except => :list

  def authorize_action
    response.headers['Access-Control-Allow-Origin'] = '*'
    @fedoraObject = ActiveFedora::Base.find(params['id'])
    authorize!(:read, params['id'])
  end
  private :authorize_action

  def generate_manifest(collection)
    manifest = IIIF::Presentation::Manifest.new(
      '@id' => iiif_apis_manifest_url(id: collection.id),
      'label' => collection.title,
      'description' => collection.description,
      'license' => collection.rights.first,
      'logo' => view_context.asset_url('iiif_nm_logo.jpg'),
      'within' => collection_within(collection),
      'metadata' => collection_metadata(collection)
    )
    manifest.sequences << generate_sequence(collection)
    manifest
  end
  private :generate_manifest

  def collection_within(collection)
    return '' unless collection.parent.present?
    collections.collection_url(collection.parent)
  end
  private :collection_within

  def collection_metadata(collection)
    (GalterCollectionPresenter.terms - [
      :title, :description, :rights, :total_items, :size]).map {|o|
      next unless collection[o].present?
      label = t(:simple_form)[:labels][:collection][o] || o.to_s.titleize
      { 'label' => label, 'value' => collection[o] }
    }.compact
  end
  private :collection_metadata

  def manifest
    render json: generate_manifest(@fedoraObject)
  end

  def authorized_pageable_members(collection)
    collection.pageable_members.select {|gf|
      can?(:read, gf['id'])
    }
  end
  private :authorized_pageable_members

  def add_canvases_to_sequence(collection, iif_sequence)
    authorized_pageable_members(collection).each do |gf|
      iif_sequence.canvases << generate_canvas(gf)
    end
    iif_sequence
  end
  private :add_canvases_to_sequence

  def generate_sequence(collection, name='basic')
    iif_sequence = IIIF::Presentation::Sequence.new(
      '@id' => iiif_apis_sequence_url(id: collection.id, name: name),
      'label' => name
    )
    add_canvases_to_sequence(collection, iif_sequence)
  end
  private :generate_sequence

  def sequence
    render json: generate_sequence(@fedoraObject, params['name'])
  end

  def page_number(gf_solr)
    "p#{gf_solr['page_number_actual_isi']}"
  end
  private :page_number

  def solarized_gf_solr(gf_solr)
    if gf_solr.is_a?(GenericFile)
      gf_solr = gf_solr.to_solr
    end
    gf_solr.with_indifferent_access
  end

  def generate_canvas(generic_file, name=nil)
    gf_solr = solarized_gf_solr(generic_file)
    name ||= page_number(gf_solr)
    canvas = IIIF::Presentation::Canvas.new(
      '@id' => iiif_apis_canvas_url(id: gf_solr['id'], name: name),
      'label' => name,
      'height' => gf_solr['height_isim'].first.to_i,
      'width' => gf_solr['width_isim'].first.to_i
    )
    canvas.images << generate_annotation(gf_solr, name)
    canvas
  end
  private :generate_canvas

  def canvas
    render json: generate_canvas(@fedoraObject, params['name'])
  end

  def generate_annotation(generic_file, name=nil)
    gf_solr = solarized_gf_solr(generic_file)
    name ||= page_number(gf_solr)
    annotation = IIIF::Presentation::Annotation.new(
      '@id' => iiif_apis_annotation_url(id: gf_solr['id'], name: name),
      'on' => iiif_apis_canvas_url(id: gf_solr['id'], name: name)
    )
    annotation.resource = image_resource(gf_solr)
    annotation
  end
  private :generate_annotation

  def image_resource(gf_solr)
    image_resource = IIIF::Presentation::ImageResource.new(
      '@id' => Riiif::Engine.routes.url_helpers.image_url(
        gf_solr['id'], size: 'full', host: root_url.gsub(/\/$/, '')),
      'format' => 'image/jpeg',
      'height' => gf_solr['height_isim'].first.to_i,
      'width' => gf_solr['width_isim'].first.to_i,
      'service' => {
        '@id' => "#{root_url}image-service/#{gf_solr['id']}",
        '@context' => 'http://iiif.io/api/image/2/context.json',
        'profile' => 'http://iiif.io/api/image/2/profiles/level2.json'
      }
    )
  end
  private :image_resource

  def annotation
    render json: generate_annotation(@fedoraObject, params['name'])
  end

  def list
    render json: {}
  end
end
