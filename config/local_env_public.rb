# This file contains public ENV vars necessary to run the app locally.
# This file is in the RCS
# NOTE: To override the variables in this file include them
#       in your `config/local_env.rb' file.

# Authentication and authorization
ENV['LDAP_SERVER']   = 'registry.northwestern.edu'
ENV['LDAP_PORT']     = '636'
ENV['LDAP_USERNAME'] = 'cn=galterlib,ou=service,dc=northwestern,dc=edu'
ENV['OPENAM_BASE_URL'] = 'https://websso.it.northwestern.edu/'
ENV['OPENAM_COOKIE_NAME'] = 'openAMssoToken'

# Email
ENV['SMTP_SERVER'] = 'ns.northwestern.edu'
ENV['DEFAULT_EMAIL_SENDER'] = 'ghsl-ref@northwestern.edu'
ENV['SERVER_ADMIN_EMAIL'] = 'galter-is@listserv.it.northwestern.edu'

# Website
ENV['BASE_URL'] = 'http://www.galter.northwestern.edu'

# Search and proxy and identity services
ENV['VOYAGER_BASE_URL'] = 'http://voyager.library.northwestern.edu:11014/vxws/'
ENV['NU_LIB_SFX_PREFIX'] = 'http://sfxprd.library.northwestern.edu/sfx'
ENV['PRIMO_BASE_URL'] = 'http://nwu-primo.hosted.exlibrisgroup.com'
ENV['PRIMO_SANDBOX_BASE_URL'] = 'http://nwu-primosb.hosted.exlibrisgroup.com'
ENV['OPAC_URL'] = 'http://nucat.library.northwestern.edu/cgi-bin/Pwebrecon.cgi?BBID='
ENV['PUBMED_EMAIL'] = 'galter-is@listserv.it.northwestern.edu'
ENV['PUBMED_URL'] = 'http://www.ncbi.nlm.nih.gov/pubmed/PMID?otool=norwelib&holding=norwelib'
ENV['ILLIAD_URL'] = 'https://northwestern.illiad.oclc.org/illiad/illiad.dll?'
ENV['EUTILS_HOST'] = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/'

# EZProxy
ENV['PROXY_URL'] = 'ezproxy.galter.northwestern.edu'
begin
  if ['staging', 'development'].include?(Rails.env)
    ENV['PROXY_URL'] = 'ezproxy.ghsl.northwestern.edu'
  end
rescue
end
ENV['EZPROXY_DIR'] = '/opt/ezproxy'
ENV['EZPROXY_SSH_KEY_FILE'] = 'config/ezproxy-key'
