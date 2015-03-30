
# Constants for run.rb

# Copy this file to foo_config.rb where "foo" is the collection name,
# and edit as necessary.

Schema_sql = "./schema.sql"

# Debug mode. 

Fx_debug = false # true or false

# Full path to the EAD file that you want to parse.

Ead_file = './gvbfind(20100923).xml'

# URL for the rest api. Include userid:password as necessary.

Base_url = "http://fedoraAdmin:asd89jio32kj@steve-2315.fsm.northwestern.edu:8080/fedora"

# Full path to the foxml  and contentmeta erb templates.

Generic_t_file = "./generic.foxml.xml.erb"
Contentmeta_t_file = "./contentmeta.xml.erb"

# A namespace for your Fedora pids. Like 'demo' where a pid is
# demo:1. Spaces and underscores not allowed.

Pid_namespace = "sufia"

# Currently, there are two of these 'tobin', and 'hull'. They
# determine which hardcoded algorithm is used to determine file paths
# for digital assets in the collection.

Path_key_name = 'gvblack'

# URL root for web services for a given collection.

Digital_assets_url = "http://galter.northwestern.edu/repo"

# Right now this is simply a path. The files are relative to this
# path. This might change to a regular expression. Example relative
# path: data/2004-M-088.0007/2004-M-088.0007.txt

Digital_assets_home = '/mnt/1TBUSB/'
