#!/usr/bin/env ruby

# Script to update/migrate all Actionability docs to update the 'Nature of Intervention' property to be items based. Also add a new 'Notes' property to Score.Final Scores.Metadata property.
# The script needs to be run for both the 'working' KB as well as the 'release KB'


require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/rest/apiCaller'
require "genboreeTools"


# Update the following fields based on your KB settings
gbGroup = 'actionability'
gbKb = 'actionability' # Needs to be run for the 'release KB' as well. 
collName = 'combined_model'


# Get all the existing docs
apiCaller = getApiCallerForObject("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true")
apiCaller.get( {:grp => gbGroup, :kb => gbKb, :coll => collName } )
docs = apiCaller.parseRespBody['data']
$stderr.puts "docs size: #{docs.size}"

# Get the model
apiCaller = getApiCallerForObject("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?")
apiCaller.get( {:grp => gbGroup, :kb => gbKb, :coll => collName } )
model = apiCaller.parseRespBody['data']
# Change Nature of Intervention to be items based under Stage 2
model['properties'][5]['properties'][6] = {"name"=>"Acceptability of Intervention", "category"=>true, "fixed"=>true, "properties"=>[{"name"=>"Natures of Intervention", "items"=>[{"name"=>"Nature of Intervention", "category"=>false, "fixed"=>false, "properties"=>[{"name"=>"Key Text", "required"=>true, "domain"=>"string"}, {"name"=>"References", "items"=>[{"name"=>"Reference", "required"=>true, "domain"=>"url", "identifier"=>true, "index"=>true, "unique"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}, {"name"=>"Additional Tiered Statements", "items"=>[{"name"=>"RecommendationID", "properties"=>[{"name"=>"Recommendation"}, {"name"=>"Tier", "domain"=>"enum(1,2,3,4,5,Not provided)"}, {"name"=>"References", "items"=>[{"name"=>"Reference", "required"=>true, "domain"=>"url", "identifier"=>true, "index"=>true, "unique"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}], "domain"=>"autoID(REC, increment[3],,)", "identifier"=>true, "index"=>true, "unique"=>true}], "fixed"=>true, "domain"=>"[valueless]"}, {"name"=>"Tier", "domain"=>"enum(1,2,3,4,5,Not provided)"}], "domain"=>"autoID(NOI, increment[3],,)", "identifier"=>true, "index"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}], "domain"=>"[valueless]"}
# Add optional Notes field under Score
model['properties'][6]['properties'][1]['properties'][0]['properties'].push({"name"=>"Notes"})
# Add Full Name to Outcome and interventions
model['properties'][5]['properties'][0]['items'][0]['properties'].push( { "name" => "FullName" } )
model['properties'][5]['properties'][0]['items'][0]['properties'][0]['items'][0]['properties'] = [{"name" => "FullName"}]
#puts JSON.pretty_generate(model['properties'][5]['properties'][0])
# Update model
apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?unsafeForceModelUpdate=true")
apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName }, model.to_json )
modelUpdated= true
if(apiCaller.succeeded?)
  $stderr.puts "MODEL UPDATE SUCCESSFUL."
  modelUpdated = true
else
  $stderr.puts "MODEL_UPDATE_FAILED: #{apiCaller.respBody.inspect}"
  modelUpdated = false
end

if(modelUpdated)
  docsReportInfo = {}
  docs.each { |doc|
    kbd = BRL::Genboree::KB::KbDoc.new(doc)
    docId = kbd.getPropVal('ActionabilityDocID')
    aoiDoc = kbd.getSubDoc('ActionabilityDocID.Stage 2.Acceptability of Intervention')
    $stderr.puts "Checking doc: #{docId.inspect}"
    if(!aoiDoc['Acceptability of Intervention'].nil? and !aoiDoc.getSubDoc('Acceptability of Intervention.Nature of Intervention')['Nature of Intervention'].nil?)
      $stderr.puts "DOC_UPDATE_REQUIRED"
      docsReportInfo[docId] = { :updateReq => "UPDATE REQUIRED" }
      noiDoc = aoiDoc.getSubDoc('Acceptability of Intervention.Nature of Intervention').deep_clone
      noiDoc.setPropVal('Nature of Intervention', '')
      noiProps = noiDoc.getPropProperties('Nature of Intervention')
      # Notes was deprecated a while back in the previous model. We relabeled Key Text as Notes.
      noiProps.delete("Notes") if(noiProps.key?("Notes"))
      kbd.setPropProperties('ActionabilityDocID.Stage 2.Acceptability of Intervention', { "Natures of Intervention" => {  "items" => [noiDoc] } })
      docsReportInfo[docId][:updateDone] = "OK"
      apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}")
      apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName, :doc => docId }, kbd.to_json )
      if(apiCaller.succeeded?)
        docsReportInfo[docId][:updateDone] = "OK"
        $stderr.puts "DOC_UPDATE_SUCCESSFUL"
      else
        docsReportInfo[docId][:updateDone] = "FAILED"
        $stderr.puts "DOC_UPDATE_FAILED: #{apiCaller.respBody.inspect}"
      end
    else
      docsReportInfo[docId] = { :updateReq => "UPDATE NOT REQUIRED" }
      $stderr.puts "DOC_UPDATE_NOT_REQUIRED"
    end
    $stderr.puts "*****************************"
  }
  $stdout.puts "Migration Report"
  $stdout.puts "DocID\tUpdate Required?\tUpdate Status"
  docsReportInfo.each_key { |docId|
    $stdout.print "#{docId}\t#{docsReportInfo[docId][:updateReq]}"
    if(docsReportInfo[docId].key?(:updateDone))
      $stdout.print "\t#{docsReportInfo[docId][:updateDone]}"
    end
    $stdout.print "\n"
  }
  $stderr.puts "Done running migration."
else
  exit(1)
end

