#!/usr/bin/env ruby

# Script to update/migrate all Actionability docs to update the following field values to be compatible with the updated model (>1-2 in 100 has been changed to <1-2 in 100)
# *ActionabilityDocID.Stage 2.Nature of the Threat.Prevalence of the Genetic Disorder.Key Text
# *ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.Key Text


require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/rest/apiCaller'


# create ApiCaller object
def getPasswordForUser(user)
  dbrc = BRL::DB::DBRC.new()
  dbrcRec = dbrc.getRecordByHost("localhost", :api)
  apiCaller = BRL::Genboree::REST::ApiCaller.new( "localhost", "/REST/v1/usr/#{user}?", dbrcRec[:user], dbrcRec[:password] )
  resp = apiCaller.get()
  apiCaller.parseRespBody()
  if(not apiCaller.succeeded?())
    raise "Api call failed (get), details:\n  response=#{resp}\n  request=#{apiCaller.fullApiUri()}\n  fullResponse=#{apiCaller.respBody()}"
  end
  dbs = apiCaller.apiDataObj
  return dbs['password']
end

# Update the following fields based on your KB settings
gbHost = "localhost"
gbGroup = "actionability"
gbKb = "actionability"
collName = "combined_model"
acApiUser = "genbadmin"
acApiPwd = getPasswordForUser(acApiUser)

# First update the model
apiCaller = BRL::Genboree::REST::ApiCaller.new(gbHost, "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?", acApiUser, acApiPwd)
apiCaller.get( {:grp => gbGroup, :kb => gbKb, :coll => collName } )
model = apiCaller.parseRespBody['data']
enumL = "enum(<1-2 in 100, 1-2 in 500, 1-2 in 1000, 1-2 in 5000, 1-2 in 10000, 1-2 in 50000, < 1-2 in 100000, Unknown)"
model['properties'][5]['properties'][3]['properties'][0]['properties'][0]['domain'] = enumL.dup
model['properties'][5]['properties'][5]['properties'][1]['properties'][0]['domain'] = enumL.dup
apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?unsafeForceModelUpdate=true")
apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName }, model.to_json )
if(apiCaller.succeeded?)
  $stderr.puts "MODEL UPDATE SUCCESSFUL."
else
  $stderr.puts "MODEL_UPDATE_FAILED: #{apiCaller.respBody.inspect}"
end

# Get All docs and replace the deprecated values if present
apiCaller = BRL::Genboree::REST::ApiCaller.new(gbHost, "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true", acApiUser, acApiPwd)
apiCaller.get( {:grp => gbGroup, :kb => gbKb, :coll => collName } )
docs = apiCaller.parseRespBody['data']
docsReportInfo = {}
$stderr.puts "Got docs. Size: #{docs.size}"
propsToCheck = ["ActionabilityDocID.Stage 2.Nature of the Threat.Prevalence of the Genetic Disorder.Key Text", "ActionabilityDocID.Stage 2.Threat Materialization Chances.Prevalence of the Genetic Mutation.Key Text"]
docs.each { |doc|
  kbd = BRL::Genboree::KB::KbDoc.new(doc)
  docId = kbd.getPropVal('ActionabilityDocID')
  $stderr.puts "Checking doc: #{docId.inspect}"
  updateReq = false
  docsReportInfo[docId] = { :updateReq => "NO UPDATE REQUIRED" }
  propsToCheck.each { |prop|
    begin
      subDoc = kbd.getSubDoc(prop)
      if(subDoc and !subDoc['Key Text'].nil? and subDoc['Key Text']['value'] == ">1-2 in 100") 
        subDoc['Key Text']['value'] = "<1-2 in 100"
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

