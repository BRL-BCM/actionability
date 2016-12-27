#!/bin/bash

set -e  # stop on first error

rm -rf /usr/local/brl/local/lib/ruby/site_ruby/1.8/brl/genboree/rest/extensions/clingenActionability
cp -r src/ruby/brl/genboree/rest/extensions/clingenActionability  /usr/local/brl/local/lib/ruby/site_ruby/1.8/brl/genboree/rest/extensions/

rm -rf /usr/local/brl/local/conf/apiExtensions/clingenActionability
cp -r src/conf/apiExtensions/clingenActionability  /usr/local/brl/local/conf/apiExtensions/

rm -rf /usr/local/brl/local/rails/redmine/sencha-deploy/genboree_ac
cp -r src/redmine/sencha-deploy/genboree_ac  /usr/local/brl/local/rails/redmine/sencha-deploy/

rm -rf /usr/local/brl/local/rails/redmine/plugins/genboree_ac
cp -r src/redmine/plugins/genboree_ac  /usr/local/brl/local/rails/redmine/plugins/

cd ${DIR_TARGET}/rails/redmine
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake redmine:plugins
cd -
