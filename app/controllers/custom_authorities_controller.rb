class CustomAuthoritiesController < ApplicationController
  def query_mesh
    base_sparql_mesh_uri ="https://id.nlm.nih.gov/mesh/sparql?format=JSON&limit=10&inference=true&query=PREFIX%20rdfs%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23%3E%0D%0APREFIX%20meshv%3A%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%2Fvocab%23%3E%0D%0APREFIX%20mesh2018%3A%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0A%0D%0ASELECT%20%3Fd%20%3FdName%0D%0AFROM%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0AWHERE%20%7B%0D%0A%20%20%3Fd%20a%20meshv%3ADescriptor%20.%0D%0A%20%20%3Fd%20rdfs%3Alabel%20%3FdName%0D%0A%20%20FILTER(REGEX(%3FdName%2C%27"
    end_sparql_mesh_uri = "%27%2C%20%27i%27))%20%0D%0A%7D%20%0D%0AORDER%20BY%20%3Fd%20%0D%0A"
    if params[:q].present?
      hits = JSON.parse(HTTParty.get(
        base_sparql_mesh_uri + params[:q] + end_sparql_mesh_uri
      ))
      if hits = hits.try(:[], "results").try(:[], "bindings")
        hits.map!{|x| x["dName"]["value"]}
      else
        hits = ["Error Searching"]
      end
    end
    render json: hits
  end

  def lcsh_names
    lcnaf_base_uri = "http://id.loc.gov/authorities/names/suggest/?q="
    if params[:q].present?
      hits = JSON.parse(HTTParty.get(
        lcnaf_base_uri + "*#{params[:q].gsub(/\s/,'*')}*"
      ))
      hits = hits.try(:[], 1) ? hits[1] : ["Error Searching"]
    end
    
    render json: hits
  end

  def ldap_cn_query
    params[:q].tr(',', '').strip.gsub(/ +/, ' ').split(' ').map {|o|
      "(cn=#{o}*)" }.join('')
  end
  private :ldap_cn_query

  def ldap_orcid_query
    return unless bare_orcid = Sufia::OrcidValidator.match(params[:q]).try(:[], 0)
    "(eduPersonOrcid=https://orcid.org/#{bare_orcid})"
  end
  private :ldap_orcid_query

  def verify_user_in_ldap(results)
    ldap_results = Nuldap.new.multi_search(
      "cn=#{params['q'].strip.gsub(/, +/, ',')}")

    if ldap_results.present?
      if ldap_results.count > 1
        results[:message] = "Found multiple users, please be more specific."
      else
        results[:verified] = true
        results[:standardized_name] = Nuldap.standardized_name(
          ldap_results.first)
        results[:netid] = ldap_results.first['uid'].try(:first)
      end
    else
      results[:message] = "User \"#{params[:q]}\" not found in the NU directory."
    end
  end
  private :verify_user_in_ldap

  def vivo_profile(results)
    results[:vivo] = {}
    if net_vivo = NetIdToVivoId.find_by(netid: results[:netid])
      results[:vivo][:id] = net_vivo.vivoid
      results[:vivo][:profile] = "#{ENV['VIVO_PROFILES']}#{net_vivo.vivoid}"
      results[:vivo][:full_name] = net_vivo.full_name
    end
  end
  private :vivo_profile

  def verify_user
    results = { verified: false }
    if params[:q].blank? || params[:q].length < 3
      results[:message] = "Couldn't look-up user '#{params[:q]}', query too short."
      render :layout => false, :text => results.to_json and return
    end
    verify_user_in_ldap(results)
    vivo_profile(results)
    render :layout => false, :text => results.to_json
  end

  def query_users
    if params[:q].blank? || params[:q].length < 3
      render :layout => false, :text => [].to_json and return
    end

    ldap_results = Nuldap.new.multi_search(
      "(|(&#{ldap_cn_query})(uid=#{params[:q].strip}*)#{ldap_orcid_query})"
    )
    formatted_results = ldap_results.map do |entry|
      { id: entry['uid'].try(:first),
        label: Nuldap.standardized_name(entry) }
    end
    render :layout => false, :text => formatted_results.to_json
  end
end
