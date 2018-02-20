class CustomAuthoritiesController < ApplicationController
  def query_mesh
    terms = []
    if params[:q].present?
      authority = Qa::Authorities::Mesh.new
      terms = authority.search(params[:q].to_s.downcase)
    end
    render :layout => false, :text => terms.to_json
  end

  def lcsh_names
    lowQuery = params['q'].to_s.downcase
    hits = []
    hits = SubjectLocalAuthorityEntry.where(
      '"lowerLabel" like ?', "#{lowQuery}%").limit(25).pluck(
        "label, url").map {|hit| { label: hit[0], uri: hit[1] } }
    render :layout => false, :text => hits.to_json
  end

  def ldap_cn_query
    params[:q].tr(',', '').strip.gsub(/ +/, ' ').split(' ').map {|o|
      "(cn=#{o}*)" }.join('')
  end
  private :ldap_cn_query

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
      "(|(&#{ldap_cn_query})(uid=#{params[:q].strip}*))")
    formatted_results = ldap_results.map do |entry|
      { id: entry['uid'].try(:first),
        label: Nuldap.standardized_name(entry) }
    end
    render :layout => false, :text => formatted_results.to_json
  end
end
