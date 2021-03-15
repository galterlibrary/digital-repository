# This file contains public ENV vars necessary to run the app locally.
# This file is in the RCS
# NOTE: To override the variables in this file include them
#       in your `config/local_env.rb' file.

# Authentication and authorization
#ENV['LDAP_SERVER']   = 'localhost'
ENV['LDAP_SERVER']   = 'registry.northwestern.edu'
ENV['LDAP_PORT']     = '636'

begin
  if Rails.env == 'production'
    ENV['SSO_SIGN_OUT_URL'] = '/Shibboleth.sso/Logout?return=https%3A%2F%2Fprd-nusso.it.northwestern.edu%2Fnusso%2FXUI%2F%23logout%26goto%3Dhttps%253A%252F%252Fdigitalhub.northwestern.edu'
  else
    ENV['SSO_SIGN_OUT_URL'] = '/Shibboleth.sso/Logout?return=https%3A%2F%2Fuat-nusso.it.northwestern.edu%2Fnusso%2FXUI%2F%23logout%26goto%3Dhttps%253A%252F%252Fvtfsmghslrepo01.fsm.northwestern.edu'
  end
rescue
end

# Email
ENV['SMTP_SERVER'] = 'ns.northwestern.edu'
ENV['SERVER_ADMIN_EMAIL'] = 'digitalhub@northwestern.edu'
ENV['TECH_ADMIN_EMAIL'] = 'GALTER-IS@LISTSERV.IT.NORTHWESTERN.EDU'

ENV['VIVO_PROFILES'] = 'http://vfsmvivo.fsm.northwestern.edu/vivo/individual?uri=http%3A%2F%2Fvivo.northwestern.edu%2Findividual%2F'

ENV['FITS_PATH_GLOBAL'] = '/var/www/apps/fits-0.8.6/fits.sh'

ENV['PRODUCTION_URL'] = 'https://digitalhub.northwestern.edu'

ENV['FEDORA_BINARY_PATH'] = '/hydra-jetty/fcrepo4-data/fcrepo.binary.directory'
