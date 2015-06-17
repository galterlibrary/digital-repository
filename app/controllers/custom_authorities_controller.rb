class CustomAuthoritiesController < ApplicationController
  def query_mesh
    authority = Qa::Authorities::Mesh.new
    authority.search(params[:q], nil)
    render :layout => false, :text => authority.results.to_json
  end

  def ldap_cn_query
    params[:q].tr(',', '').strip.gsub(/ +/, ' ').split(' ').map {|o|
      "(cn=#{o}*)" }.join('')
  end
  private :ldap_cn_query

  def verify_user_in_ldap(results)
    ldap_results = Nuldap.new.multi_search("(&#{ldap_cn_query})")

    if ldap_results.present?
      if ldap_results.count > 1
        results[:message] = "Found multiple users, please be more specific."
      else
        results[:verified] = true
        results[:first] = ldap_results.first['givenName'].try(:first)
        results[:last] = ldap_results.first['sn'].try(:first)
      end
    else
      results[:message] = "User \"#{params[:q]}\" not found in the NU directory."
    end
  end
  private :verify_user_in_ldap

  def verify_user
    results = { verified: false }
    if params[:q].blank? || params[:q].length < 3
      results[:message] = "Couldn't look-up user '#{params[:q]}', query too short."
      render :layout => false, :text => results.to_json and return
    end
    verify_user_in_ldap(results)
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
        label: "#{entry['sn'].try(:first)}, #{entry['givenName'].try(:first)}" }
    end
    render :layout => false, :text => formatted_results.to_json
  end
end
