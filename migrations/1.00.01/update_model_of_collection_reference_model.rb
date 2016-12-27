#!/usr/bin/env ruby

require 'genboreeTools'


group_name = 'actionability'
work_kb_name = 'actionability'
release_kb_name = 'actionability_release'
coll = 'reference_model'

api_put( "/REST/v1/grp/#{group_name}/kb/#{work_kb_name}/coll/#{coll}/model?unsafeForceModelUpdate=true", File.read("kb_collections/#{coll}.json") )
api_put( "/REST/v1/grp/#{group_name}/kb/#{release_kb_name}/coll/#{coll}/model?unsafeForceModelUpdate=true", File.read("kb_collections/#{coll}.json") )

docs_w = api_get( "/REST/v1/grp/#{group_name}/kb/#{work_kb_name}/coll/#{coll}/docs?format=json&detailed=true&matchProp=Reference.Category&matchValues=OMIM&matchMode=exact" )
docs_r = api_get( "/REST/v1/grp/#{group_name}/kb/#{release_kb_name}/coll/#{coll}/docs?format=json&detailed=true&matchProp=Reference.Category&matchValues=OMIM&matchMode=exact" )

api_put( "/REST/v1/grp/#{group_name}/kb/#{work_kb_name}/coll/#{coll}/docs?format=json"   , docs_w ) if docs_w.size > 0
api_put( "/REST/v1/grp/#{group_name}/kb/#{release_kb_name}/coll/#{coll}/docs?format=json", docs_r ) if docs_r.size > 0
