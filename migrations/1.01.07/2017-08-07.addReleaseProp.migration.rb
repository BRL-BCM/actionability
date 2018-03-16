#!/usr/bin/env ruby

# Migration script to add the new "Release" property to documents that have been released. 


require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/rest/apiCaller'
require "genboreeTools"

gbGroup = 'actionability'
gbKb    = 'actionability'
gbRelKb = 'actionability_release'
collName = 'combined_model'

# Get all the existing docs
apiCaller = getApiCallerForObject("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true")
apiCaller.get( {:grp => gbGroup, :kb => gbKb, :coll => collName } )
docs = apiCaller.parseRespBody['data']
$stderr.puts "docs size: #{docs.size}"

# Update the model if required
apiCaller = getApiCallerForObject("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?")
apiCaller.get( {:grp => gbGroup, :kb => gbKb, :coll => collName } )
model = apiCaller.parseRespBody['data']
apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?unsafeForceModelUpdate=true")
model['properties'][8] = {"name"=>"Release", "properties"=>[{"name"=>"Notes", "description"=>"Some explaination from the user releasing the document."}, {"name"=>"kbRevision-PairedKB", "description"=>"KB Revision number of the Actionability Doc in the OTHER track. Working KB would have the revision number of the release KB and vice versa", "domain"=>"posInt"}, {"name"=>"ReasonCode", "description"=>"One of the 4 options selected by the user during release OR for first time releases, the default", "properties"=>[{"name"=>"Reason"}], "default"=>"Q0", "domain"=>"enum(Q0,Q1,Q2,Q3,Q4)"}, {"name"=>"Date", "domain"=>"date"}, {"name"=>"ReleasedBy", "properties"=>[{"name"=>"First Name"}, {"name"=>"Last Name"}], "domain"=>"gbAccount"}], "default"=>"1.0.0"}
# First update the working KB
apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName }, model.to_json )
if(apiCaller.succeeded?)
  $stderr.puts "MODEL UPDATE SUCCESSFUL FOR WORKING kb."
else
  $stderr.puts "MODEL UPDATE FAILED FOR WORKING Kb: #{apiCaller.respBody.inspect}"
  exit(1)
end
# Next update the release KB
apiCaller.put( {:grp => gbGroup, :kb => gbRelKb, :coll => collName }, model.to_json )
if(apiCaller.succeeded?)
  $stderr.puts "MODEL UPDATE SUCCESSFUL FOR WORKING kb."
else
  $stderr.puts "MODEL UPDATE FAILED FOR WORKING Kb: #{apiCaller.respBody.inspect}"
  exit(1)
end

# Go over All docs and add the new Release prop if the doc has been released
docsReportInfo = {}
docs.each { |doc|
  begin
    kbd = BRL::Genboree::KB::KbDoc.new(doc)
    docId = kbd.getPropVal('ActionabilityDocID')
    $stderr.puts "Checking doc: #{docId.inspect}"
    updateReq = false
    docsReportInfo[docId] = { :updateReq => "NO UPDATE REQUIRED" }
    kbdProps = kbd.getPropProperties("ActionabilityDocID")
    currStatus = kbd.getPropVal("ActionabilityDocID.Status")
    if(currStatus == "Released" and !kbdProps.key?("Release"))
      docsReportInfo[docId][:updateReq] = "UPDATE REQUIRED"
      updateReq = true
    end
    if(updateReq)
      timeObj = Time.new()
      date = "#{timeObj.year}-#{timeObj.month}-#{timeObj.day}"
      kbdProps['Release'] = {
        "value" => "1.0.0",
        "properties" => {
          "Notes" => {  "value" => "" },
          "kbRevision-PairedKB" => { "value" => 0},
          "ReasonCode" => { "value" => "Q0", "properties" => { "Reason" => { "value" => "Initial Release" } } },
          "Date" => { "value" => date },
          "ReleasedBy" => { "value" => 'genbadmin', "properties" => {  "First Name" => { "value" => ""}, "Last Name" => {  "value" => "" }   }  }
        }
      }
      apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}")
      apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName, :doc => docId }, kbd.to_json )
      if(apiCaller.succeeded?)
        # Now update the doc in the release KB
        revisionNum = apiCaller.parseRespBody['metadata']['revision']
        apiCaller.get({:grp => gbGroup, :kb => gbRelKb, :coll => collName, :doc => docId })
        if(apiCaller.succeeded?)
          kbdRel = BRL::Genboree::KB::KbDoc.new(apiCaller.parseRespBody['data'])
          kbdRelProps = kbdRel.getPropProperties("ActionabilityDocID")
          kbdRelProps["Release"] = kbdProps['Release']
          kbdRel.setPropVal("ActionabilityDocID.Release.kbRevision-PairedKB", revisionNum)
          apiCaller.put( {:grp => gbGroup, :kb => gbRelKb, :coll => collName, :doc => docId }, kbdRel.to_json )
          if(apiCaller.succeeded?)
            # Finally update the working KB with the revision number of the release KB doc
            relRevisionNum = apiCaller.parseRespBody['metadata']['revision']
            kbd.setPropVal("ActionabilityDocID.Release.kbRevision-PairedKB", relRevisionNum)
            apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName, :doc => docId }, kbd.to_json )
            if(apiCaller.succeeded?)
              docsReportInfo[docId][:updateDone] = "OK"
              $stderr.puts "DOC_UPDATE_SUCCESSFUL"
            else
              docsReportInfo[docId][:updateDone] = "FAILED"
              $stderr.puts "DOC_UPDATE_FAILED: #{apiCaller.respBody.inspect}"
            end
          else
            docsReportInfo[docId][:updateDone] = "FAILED"
            $stderr.puts "DOC_UPDATE_FAILED (Release Doc Update Failed!!): #{apiCaller.respBody.inspect}"
          end
        else
          docsReportInfo[docId][:updateDone] = "FAILED"
          $stderr.puts "DOC_UPDATE_FAILED (Release Doc Missing!!): #{apiCaller.respBody.inspect}"
        end
      else
        docsReportInfo[docId][:updateDone] = "FAILED"
        $stderr.puts "DOC_UPDATE_FAILED: #{apiCaller.respBody.inspect}"
      end
    else
      $stderr.puts "DOC_UPDATE_NOT_REQUIRED"
    end
    $stderr.puts "*****************************"
  rescue => err
    $stderr.puts err
    $stderr.puts err.backtrace.join("\n")
    exit(1)
  end
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

