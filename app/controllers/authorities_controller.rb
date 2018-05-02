require 'rdf'
require 'cgi'

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch('q', '')
    term = params[:term]
    hits = if ['location', 'based_near'].include?(term)
      GeoNamesResource.find_location(s)
    elsif ['lcsh', 'subject_geographic'].include?(term)
      get_results(term, s)
    else
      LocalAuthority.entries_by_term(params[:model], params[:term], s) rescue []
    end
    render json: hits
  end
  
  def get_results(subject, search)
    # the /suggest path limits results to 10
    lcsh_base_uri = "http://id.loc.gov/authorities/subjects/suggest/?q="
    # can increase limit to max 20 with '&rows=20'
    fast_geo_uri = "http://fast.oclc.org/searchfast/fastsuggest?fl=suggest51&wt=json&query="
    
    if subject == 'lcsh'
      result = JSON.parse(HTTParty.get(
        lcsh_base_uri + "#{search.gsub(/\s/,'*')}*"
      ))
      result = result.try(:[], 1) ? result[1] : ["Error Searching"]
    elsif subject == 'subject_geographic'
      result = HTTParty.get(fast_geo_uri + search)
      if result = result.try(:[], "response").try(:[], "docs")
        result.map!{ |x| x["suggest51"] }
      else
        result = ["Error Searching"]
      end
    end
    
    return result
  end
end
