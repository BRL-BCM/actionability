#!/usr/bin/env ruby

# Migration script to update Key Text values of the properties  'ActionabilityDocID.Stage 2.Nature of the Threat.Prevalance of the Genetic Disorder' and 'ActionabilityDocID.Stage 2.Threat Materialization hances.Prevalance of Genetic Mutation' for all Actionability docs. All values '<1-2 in 100' need to be converted to '>1-2 in 100' after updating the model. Also set the default for Relative Risk Key Text as 'Unknown'


require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/rest/apiCaller'
require "genboreeTools"


gbGroup = 'actionability'
gbKb    = 'actionability_release'
collName = 'combined_model'

# Get all the existing docs
apiCaller = getApiCallerForObject("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true")
apiCaller.get( {:grp => gbGroup, :kb => gbKb, :coll => collName } )
docs = apiCaller.parseRespBody['data']
$stderr.puts "docs size: #{docs.size}"

# Update the model
apiCaller = getApiCallerForObject("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?")
apiCaller.get( {:grp => gbGroup, :kb => gbKb, :coll => collName } )
model = apiCaller.parseRespBody['data']
enumL = "enum(>1-2 in 100, 1-2 in 500, 1-2 in 1000, 1-2 in 5000, 1-2 in 10000, 1-2 in 50000, < 1-2 in 100000, Unknown)"
model['properties'][5]['properties'][3]['properties'][0]['properties'][0]['domain'] = enumL.dup
model['properties'][5]['properties'][5]['properties'][1]['properties'][0]['domain'] = enumL.dup
model['properties'][5]['properties'][5]['properties'][3]['items'][0]['properties'][0]['default'] = "Unknown"
apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?unsafeForceModelUpdate=true")
apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName }, model.to_json )
#if(1)
if(apiCaller.succeeded?)
  $stderr.puts "MODEL UPDATE SUCCESSFUL."
else
  $stderr.puts "MODEL_UPDATE_FAILED: #{apiCaller.respBody.inspect}"
end

# Go over All docs and replace the deprecated values if present
propsToCheck = ["ActionabilityDocID.Stage 2.Nature of the Threat.Prevalence of the Genetic Disorder.Key Text", "ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.Key Text"]
docsReportInfo = {}
docs.each { |doc|
  kbd = BRL::Genboree::KB::KbDoc.new(doc)
  docId = kbd.getPropVal('ActionabilityDocID')
  $stderr.puts "Checking doc: #{docId.inspect}"
  updateReq = false
  docsReportInfo[docId] = { :updateReq => "NO UPDATE REQUIRED" }
  propsToCheck.each { |prop|
    begin
      subDoc = kbd.getSubDoc(prop)
      if(subDoc and !subDoc['Key Text'].nil? and subDoc['Key Text']['value'] == "<1-2 in 100") 
        subDoc['Key Text']['value'] = ">1-2 in 100"
        docsReportInfo[docId][:updateReq] = "UPDATE REQUIRED"
        updateReq = true
      end
    rescue => err
      $stderr.puts "#{prop} is not present..."
    end
  }
  if(updateReq)
    apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}")
    apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName, :doc => docId }, kbd.to_json )
    #if(1)
    if(apiCaller.succeeded?)
      docsReportInfo[docId][:updateDone] = "OK"
      $stderr.puts "DOC_UPDATE_SUCCESSFUL"
    else
      docsReportInfo[docId][:updateDone] = "FAILED"
      $stderr.puts "DOC_UPDATE_FAILED: #{apiCaller.respBody.inspect}"
    end
  else
    $stderr.puts "DOC_UPDATE_NOT_REQUIRED"
  end
  $stderr.puts "*****************************"
}
$stdout.puts "Migration Report"
$stdout.puts "DocID\tUpdate Required\tUpdate Status"
docsReportInfo.each_key { |docId|
  $stdout.print "#{docId}\t#{docsReportInfo[docId][:updateReq]}"
  if(docsReportInfo[docId].key?(:updateDone))
    $stdout.print "\t#{docsReportInfo[docId][:updateDone]}"
  end
  $stdout.print "\n"
}

$stderr.puts "Done running migration."

