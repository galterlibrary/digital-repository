require 'rdf'
require 'cgi'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch('q', '')
    hits = if ['location', 'based_near'].include?(params[:term])
      GeoNamesResource.find_location(s)
    else
      LocalAuthority.entries_by_term(params[:model], params[:term], s) rescue []
    end
    render json: hits
  end
end
