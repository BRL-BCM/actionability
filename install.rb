#!/usr/bin/env ruby


# copy static files
`cp -r ./src/data/* /usr/local/brl/data/`
`chmod 600 /usr/local/brl/data/messages/conf/ac-release-wag.client-ssl.no-jks.properties`

# install app
`./install_app.sh`


require 'genboreeTools'


group_name = 'actionability'
work_kb_name = 'actionability'
release_kb_name = 'actionability_release'
header_file = '/usr/local/brl/data/redmine/html/clingen_actionability_header.html'
footer_file = '/usr/local/brl/data/redmine/html/clingen_actionability_footer.html'

# genboree group
api_put("/REST/v1/grp/#{group_name}")

# create KBs
genboree_add_kb(group_name, work_kb_name)
genboree_add_kb(group_name, release_kb_name)
genboree_set_kb_public(group_name, release_kb_name)

# get list of collections
colls = []
`ls kb_collections`.each { |x|
    x.strip!
    colls << x[0..-6] if x =~ /\.json$/
}

# create collections
colls.each { |coll|
    api_put( "/REST/v1/grp/#{group_name}/kb/#{work_kb_name}/coll/#{coll}/model", File.read("kb_collections/#{coll}.json") )
    api_put( "/REST/v1/grp/#{group_name}/kb/#{release_kb_name}/coll/#{coll}/model", File.read("kb_collections/#{coll}.json") )
}

# create project for work
redmine_add_project("actionability", "Actionability", ['genboree_ac'])
redmine_configure_project_genboree_ac("actionability", group_name, work_kb_name, work_kb_name, release_kb_name, header_file, footer_file)

# create project for release
redmine_add_project("actionability_release", "Actionability Release", ['genboree_ac'], true)
redmine_configure_project_genboree_ac("actionability_release", group_name, release_kb_name, work_kb_name, nil, header_file, footer_file)

# load data to collections
colls.each { |coll|
    filename = "kb_data/#{coll}.json.gz"
    next if coll =~ /^combined_model/ or not File.exist?(filename)
    puts "Load data from file #{filename}"
    api_put_from_file_in_chunks( "/REST/v1/grp/#{group_name}/kb/#{work_kb_name}/coll/#{coll}/docs?autoAdjust=true", "#{filename}" )
}
