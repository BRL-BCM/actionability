#!/usr/bin/env ruby

# Migration script to add the new "TemplateSets" collection to both the working and the release KBs. 


require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/rest/apiCaller'
require "genboreeTools"

gbGroup = 'actionability'
gbKb    = 'actionability'
gbRelKb = 'actionability_release'
acCollName = 'combined_model' # Actionability coll name
acRefCollName = 'reference_model' # Reference coll name


# First add the new collection
tsModel = {"identifier"=>true, "properties"=>[{"description"=>"The template set used to render the HEAD revision of the AC docs. This is also the template set with the highest rank.", "domain"=>"regexp(^TemplateSet-\\d+$)", "name"=>"CurrentTemplateSet"}, {"description"=>"item list of all templates that have been used so far", "name"=>"TemplateSets", "items"=>[{"index"=>true, "identifier"=>true, "required"=>true, "unique"=>true, "domain"=>"regexp(^TemplateSet-\\d+$)", "properties"=>[{"domain"=>"posInt", "name"=>"Rank"}, {"domain"=>"posInt", "name"=>"MinAcDocVer"}, {"domain"=>"posInt", "name"=>"MaxAcDocVer"}, {"domain"=>"date", "name"=>"Date"}, {"domain"=>"posInt", "name"=>"AcModelVer"}, {"domain"=>"posInt", "name"=>"RefModelVer"}, {"domain"=>"gbAccount", "name"=>"ReleasedBy"}], "name"=>"TemplateSet"}]}], "name"=>"TemplateSetDocID"}


# Get one doc from the actionability collection and do a no-op update and then get the version number of the document. This number + 1 will be set as the MinAcDocVer in the TemplateSets document. This will be followed by a no-op update of ALL the documents.
[gbKb, gbRelKb].each { |kb|
  apiCaller = getApiCallerForObject("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?unsafeForceModelUpdate=true")
  apiCaller.put( {:grp => gbGroup, :kb => kb, :coll => "TemplateSets" }, tsModel.to_json )
  if(apiCaller.succeeded?)
    $stderr.puts "MODEL INSERTION SUCCESSFUL FOR #{kb}."
  else
    $stderr.puts "MODEL INSERTION FAILED FOR #{kb}: #{apiCaller.respBody.inspect}"
    exit(1)
  end
  apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true")
  apiCaller.get( {:grp => gbGroup, :kb => kb, :coll => acCollName } )
  docs = apiCaller.parseRespBody['data']
  doc = BRL::Genboree::KB::KbDoc.new(docs[0])
  docId = doc.getPropVal("ActionabilityDocID")
  apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}")
  apiCaller.put( {:grp => gbGroup, :kb => kb, :coll => acCollName, :doc => docId }, doc.to_json )
  apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/vers?sort=DESC&limit=1")
  apiCaller.get( {:grp => gbGroup, :kb => kb, :coll => acCollName, :doc => docId } )
  if(!apiCaller.succeeded?)
    $stderr.puts "Could not get head version for doc #{docId}: #{apiCaller.respBody.inspect}"
    exit(1)
  end
  minAcDocVer = apiCaller.parseRespBody['data'][0]['text']['value'].to_i+1
  apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model/ver/HEAD")
  apiCaller.get( {:grp => gbGroup, :kb => kb, :coll => acCollName } )
  if(!apiCaller.succeeded?)
    $stderr.puts "Could not get head version for ac model for kb: #{kb}: #{apiCaller.respBody.inspect}"
    exit(1)
  end
  acModelVer = apiCaller.parseRespBody['data']['versionNum']['value'].to_i
  apiCaller.get( {:grp => gbGroup, :kb => kb, :coll => acRefCollName } )
  if(!apiCaller.succeeded?)
    $stderr.puts "Could not get head version for ref model for kb: #{kb}: #{apiCaller.respBody.inspect}"
    exit(1)
  end
  acRefModelVer = apiCaller.parseRespBody['data']['versionNum']['value'].to_i
  # Upload the TemplateSets doc
  tsDoc = {"TemplateSetDocID"=>{"value"=>"TemplateSetDoc001", "properties"=>{"CurrentTemplateSet"=>{"value"=>"TemplateSet-0"}, "TemplateSets"=>{"value"=>"", "items"=>[{"TemplateSet"=>{"value"=>"TemplateSet-0", "properties"=>{"MinAcDocVer"=>{"value"=>minAcDocVer}, "AcModelVer"=>{"value"=>acModelVer}, "Rank"=>{"value"=>0}, "RefModelVer"=>{"value"=>acRefModelVer}}}}]}}}}
  apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}")
  apiCaller.put( {:grp => gbGroup, :kb => kb, :coll => "TemplateSets", :doc => "TemplateSetDoc001" }, tsDoc.to_json )
  if(!apiCaller.succeeded?)
    $stderr.puts "Could not upload template sets doc for kb: #{kb}: #{apiCaller.respBody.inspect}"
    exit(1)
  end
  # Go over All docs and add the new Release prop if the doc has been released
  docsReportInfo = {}
  docs.each { |doc|
    begin
      kbd = BRL::Genboree::KB::KbDoc.new(doc)
      docId = kbd.getPropVal("ActionabilityDocID")
      apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?")
      $stderr.puts "Uploading doc: #{docId.inspect}"
      apiCaller.put( {:grp => gbGroup, :kb => kb, :coll => acCollName, :doc => docId }, doc.to_json )
      status = :OK
      if(!apiCaller.succeeded?)
        $stderr.puts "Failed to update doc: #{docId}: #{apiCaller.respBody.inspect}"
        status = :FAILED
      end
      docsReportInfo[docId] = status
      $stderr.puts "*****************************"
    rescue => err
      $stderr.puts err
      $stderr.puts err.backtrace.join("\n")
      exit(1)
    end
  }
  $stdout.puts "Migration Report: #{kb}"
  $stdout.puts "DocID\tUpdate Status"
  docsReportInfo.each_key { |docId|
    $stdout.puts "#{docId}\t#{docsReportInfo[docId]}"
  }
  $stdout.puts "***********************"
}
$stderr.puts "Done running migration."

