require 'iiif/presentation'

class IiifApisController < ApplicationController
  before_filter :authorize_action, :except => :list

  def authorize_action
    @fedoraObject = ActiveFedora::Base.find(params['id'])
    authorize!(:read, @fedoraObject)
  end
  private :authorize_action

  def generate_manifest(collection)
    manifest = IIIF::Presentation::Manifest.new(
      '@id' => iiif_apis_manifest_url(id: collection.id),
      'label' => collection.title,
      'description' => collection.description,
      'license' => collection.rights.first,
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

  def add_canvases_to_sequence(collection, iif_sequence)
    collection.members.each do |gf|
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

  def generate_canvas(generic_file, name=nil)
    name ||= "p#{generic_file.page_number}"
    canvas = IIIF::Presentation::Canvas.new(
      '@id' => iiif_apis_canvas_url(id: generic_file.id, name: name),
      'label' => name,
      'height' => generic_file.height.first.to_i,
      'width' => generic_file.width.first.to_i
    )
    canvas.images << generate_annotation(generic_file, name)
    canvas
  end
  private :generate_canvas

  def canvas
    render json: generate_canvas(@fedoraObject, params['name'])
  end

  def generate_annotation(generic_file, name=nil)
    name ||= "p#{generic_file.page_number}"
    annotation = IIIF::Presentation::Annotation.new(
      '@id' => iiif_apis_annotation_url(id: generic_file.id, name: name),
      'on' => iiif_apis_canvas_url(id: generic_file.id, name: name)
    )
    annotation.resource = image_resource(generic_file)
    annotation
  end
  private :generate_annotation

  def image_resource(generic_file)
    image_resource = IIIF::Presentation::ImageResource.new(
      '@id' => Riiif::Engine.routes.url_helpers.image_url(
        generic_file.id, size: 'full', host: root_url.gsub(/\/$/, '')),
      'format' => 'image/jpeg',
      'height' => generic_file.height.first.to_i,
      'width' => generic_file.width.first.to_i,
      'service' => {
        '@id' => "#{root_url}image-service/#{generic_file.id}",
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
