class CustomAuthoritiesController < ApplicationController
  def query_mesh
    authority = Qa::Authorities::Mesh.new
    authority.search(params[:q], nil)
    render :layout => false, :text => authority.results.to_json
  end
end
