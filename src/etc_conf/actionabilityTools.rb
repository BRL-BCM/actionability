

# set configuration of genboree_ac project
def redmine_configure_project_genboree_ac(project_identifier, ac_genboree_group, ac_kb_name, orphanet_kb_name, 
                                          release_kb_name = nil, header_include_file = nil, footer_include_file = nil)
  # find project id
  resp = redmine_api_get("/projects/#{project_identifier}.json")
  id = resp["project"]["id"]
  raise "Cannot find project with identifier: #{project_identifier}" if id.nil?
  # set record's fields
  fields = Hash.new
  fields['project_id'] = id
  fields['gbHost'] = 'localhost'
  fields['gbKb'] = "#{ac_kb_name}"
  fields['appLabel'] = nil
  fields['useRedmineLayout'] = 1
  fields['headerIncludeFileLoc'] = header_include_file
  fields['footerIncludeFileLoc'] = footer_include_file
  fields['actionabilityColl'] = 'combined_model'
  fields['referencesColl'] = 'reference_model'
  fields['genesColl'] = 'gene_data'
  fields['gbActOrphanetCollRsrcPath'] = "/REST/v1/grp/#{ac_genboree_group}/kb/#{orphanet_kb_name}/coll/orphanet_mirror"
  fields['gbGroup'] = "#{ac_genboree_group}"
  fields['gbReleaseKbRsrcPath'] = (release_kb_name.nil?) ? ("/REST/v1/grp/#{ac_genboree_group}/kb/#{ac_kb_name}") : ("/REST/v1/grp/#{ac_genboree_group}/kb/#{release_kb_name}")
  fields['templateSetsColl'] = "TemplateSets"
  fields['urlMountDir'] = "/redmine/projects/#{project_identifier}/genboree_ac/" 
  fields['isAcReleaseTrack'] = (release_kb_name.nil?) ? (1) : (0)
  fields['releaseKbBaseUrl'] = (release_kb_name.nil?) ? ("/redmine/projects/#{project_identifier}/genboree_ac/") : ("/redmine/projects/#{project_identifier}_release/genboree_ac/") # TODO - hardcoded
  fields['releasedMqConf'] = '/usr/local/brl/data/messages/conf/ac-release-wag.json'
  # check if the record exists and run insert or update
  sql = "SELECT COUNT(1) AS count FROM genboree_acs WHERE project_id=#{id}"
  if runSqlStatement_redmine(sql).first['count'].to_i == 0
    sql = sql_insert('genboree_acs', fields)
  else
    sql = sql_update('genboree_acs', fields) + " WHERE project_id=#{id}"
  end
  runSqlStatement_redmine(sql)
end
