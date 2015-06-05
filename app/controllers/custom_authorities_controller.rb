class CustomAuthoritiesController < ApplicationController
  def query_mesh
    authority = Qa::Authorities::Mesh.new
    authority.search(params[:q], nil)
    render :layout => false, :text => authority.results.to_json
  end

  def query_users
    if params[:q].blank? || params[:q].length < 3
      render :layout => false, :text => [].to_json and return
    end

    ldap_results = Nuldap.new.multi_search(
      "(|(cn=#{params[:q]}*)(uid=#{params[:q]}*))")
    formatted_results = [ldap_results].flatten.compact.map {|entry|
      { id: entry['uid'].try(:first), label: entry['displayName'].try(:first) }
    }
    render :layout => false, :text => formatted_results.to_json
  end
end
