class IiifApisController < ApplicationController
  def manifest
    render json: {}
  end

  def add_canvases_to_sequence(collection, iif_sequence)
    collection.pagable_members.each do |gf|
      iif_sequence.canvases << generate_canvas(gf)
    end
    iif_sequence
  end
  private :add_canvases_to_sequence

  def generate_sequence(collection, name='basic')
    iif_sequence = IIIF::Presentation::Sequence.new(
      '@id' => iiif_apis_sequence_path(id: collection.id, name: name),
      'label' => name
    )
    add_canvases_to_sequence(collection, iif_sequence)
  end
  private :generate_sequence

  def sequence
    collection = Collection.find(params[:id])
    render json: generate_sequence(collection, params['name'])
  end

  def generate_canvas(generic_file, name=nil)
    name ||= "p#{generic_file.page_number}"
    canvas = IIIF::Presentation::Canvas.new(
      '@id' => iiif_apis_canvas_path(id: generic_file.id, name: name),
      'label' => name,
      'height' => generic_file.height.first.to_i,
      'width' => generic_file.width.first.to_i
    )
    canvas.images << generate_annotation(generic_file, name)
    canvas
  end
  private :generate_canvas

  def canvas
    generic_file = GenericFile.find(params[:id])
    render json: generate_canvas(generic_file, params['name'])
  end

  def generate_annotation(generic_file, name=nil)
    name ||= "p#{generic_file.page_number}"
    annotation = IIIF::Presentation::Annotation.new(
      '@id' => iiif_apis_annotation_path(id: generic_file.id, name: name),
      'on' => iiif_apis_canvas_path(id: generic_file.id, name: name)
    )
    annotation.resource << generic_file.iiif_image_resource
    annotation
  end
  private :generate_annotation

  def annotation
    generic_file = GenericFile.find(params[:id])
    render json: generate_annotation(generic_file, params['name'])
  end

  def list
    render json: {}
  end
end
