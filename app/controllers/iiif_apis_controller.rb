class IiifApisController < ApplicationController
  def manifest
    render json: {}
  end

  def sequence
    render json: {}
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
