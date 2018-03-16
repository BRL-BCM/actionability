#!/usr/bin/env ruby

require 'genboreeTools'


group_name = 'actionability'
work_kb_name = 'actionability'
release_kb_name = 'actionability_release'
coll = 'combined_model'

api_put( "/REST/v1/grp/#{group_name}/kb/#{work_kb_name}/coll/#{coll}/model?unsafeForceModelUpdate=true", File.read("kb_collections/#{coll}.json") )
api_put( "/REST/v1/grp/#{group_name}/kb/#{release_kb_name}/coll/#{coll}/model?unsafeForceModelUpdate=true", File.read("kb_collections/#{coll}.json") )
