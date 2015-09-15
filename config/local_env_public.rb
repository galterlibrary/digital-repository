# This file contains public ENV vars necessary to run the app locally.
# This file is in the RCS
# NOTE: To override the variables in this file include them
#       in your `config/local_env.rb' file.

# Authentication and authorization
ENV['LDAP_SERVER']   = 'registry.northwestern.edu'
ENV['LDAP_PORT']     = '636'
ENV['OPENAM_BASE_URL'] = 'https://websso.it.northwestern.edu/'
ENV['OPENAM_COOKIE_NAME'] = 'openAMssoToken'

# Email
ENV['SMTP_SERVER'] = 'ns.northwestern.edu'
ENV['SERVER_ADMIN_EMAIL'] = 'galter-is@listserv.it.northwestern.edu'

ENV['VIVO_PROFILES'] = 'http://vfsmvivo.fsm.northwestern.edu/vivo/individual?uri=http%3A%2F%2Fvivo.northwestern.edu%2Findividual%2F'

ENV['FITS_PATH_GLOBAL'] = '/var/www/apps/fits-0.8.6/fits.sh'
