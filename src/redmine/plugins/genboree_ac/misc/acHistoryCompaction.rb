#!/usr/bin/env ruby

# Script to perform History (version/revision collections) compaction of the Release KBs for Actionability.
# Currently only suitable for the release KB


require 'brl/db/dbrc'
require 'brl/genboree/genboreeUtil'
require 'brl/genboree/dbUtil'
require 'brl/genboree/rest/apiCaller'
require 'brl/genboree/kb/mongoKbDatabase'
require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/kb/validators/docValidator'


# Standard setup stuff
gbHost = 'localhost'
# gbUser = ARGV[1]
gbGroup = 'actionability'
gbKbName = 'actionability_release'
gbCollName = 'combined_model'

# @todo implement curation mode where edits after the latest release will be kept in history
@curationMode = false

dbrc = BRL::DB::DBRC.new()
dbu = BRL::Genboree::DBUtil.new("DB:#{gbHost}", nil, nil)
genbConf = BRL::Genboree::GenboreeConfig.load()
mongoDbrcRec = dbrc.getRecordByHost(gbHost, :nosql)
# userRecs = dbu.selectUserByName(gbUser)
# userId = userRecs.first["userId"]

# Get the raw mongo db name from the KB and group name
mongoDbName = dbu.selectKbByNameAndGroupName(gbKbName, gbGroup)[0]["databaseName"]
$stderr.puts mongoDbrcRec.inspect
mdb = BRL::Genboree::KB::MongoKbDatabase.new(mongoDbName, mongoDbrcRec[:driver], { :user => mongoDbrcRec[:user], :pass => mongoDbrcRec[:password]})

# First download the dump for the versions/revisions collections for the AC collection for safe keeping
historyColl2Prop = {
  "versions" => "versionNum",
  "revisions" => "revisionNum"
}
docIds = {}
historyColl2Prop.each_key { |history|
  historyProp = historyColl2Prop[history]
  cursor = mdb.db["#{gbCollName}.#{history}"].find({}, {:sort => ["#{historyProp}.value", Mongo::DESCENDING]})
  historyFile = File.open("#{gbKbName}.#{history}", "w")
  historyDocs = []
  cursor.each { |doc|
    kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
    contentDoc = kbDoc.getPropVal("#{historyProp}.content")
    if(contentDoc and contentDoc.key?("ActionabilityDocID"))
      docId = contentDoc['ActionabilityDocID']['value']
      cc =  mdb.db["#{gbCollName}"].find({"ActionabilityDocID.value" => docId})
      cc.each { |dd|
        docIds[docId] = dd["_id"]
        historyDocs << kbDoc
      }
    end
  }
  historyFile.print(historyDocs.to_json)
  historyFile.close()
  historyDocs.clear
}

$stdout.puts "#{docIds.to_json}"


## Create the new versions/revisions docs for each doc
## Do this one doc at a time to keep memory footprint low
doc2headVer = {}
["versions", "revisions"].each { |history|
  historyProp = historyColl2Prop[history]
  historyFile = "#{gbKbName}.#{history}"
  docHistory = JSON.parse(File.read(historyFile))
  finalDocHistory = File.open("#{historyFile}.final", "w")
  finalDocHistory.print("[")
  historyCount = 0
  docIds.each_key { |docId|
    prevHistoryDoc = nil
    docHistory.each { |hdoc|
      historyKbd =   BRL::Genboree::KB::KbDoc.new(hdoc)
      historyKbd.delete("_id")
      break if(historyKbd.getPropVal("#{historyProp}.deletion"))
      contentDoc = historyKbd.getPropVal("#{historyProp}.content")
      unless(@curationMode)
        if(contentDoc and contentDoc.key?("ActionabilityDocID"))
          contentDoc = BRL::Genboree::KB::KbDoc.new(contentDoc)
           #$stderr.puts "docId: #{docId.inspect}\t#{contentDoc.getPropVal('ActionabilityDocID')}"
          if(docId == contentDoc.getPropVal('ActionabilityDocID'))
           
            if(prevHistoryDoc.nil?)
              prevHistoryDoc = historyKbd
              # Save the head version of the document. We may use its contents for the head revision of the doc if its subdocpath is not '/'
              if(history == "versions")
                doc2headVer[docId] = historyKbd.getPropVal("#{historyProp}.content")
              end
            else
              if(contentDoc.getPropProperties("ActionabilityDocID").key?("Release"))
                releaseVer = contentDoc.getPropVal("ActionabilityDocID.Release")
                
                prevHistoryDocContentDoc = BRL::Genboree::KB::KbDoc.new(prevHistoryDoc.getPropVal("#{historyProp}.content"))
                prevHistoryDocReleaseVer = prevHistoryDocContentDoc.getPropVal("ActionabilityDocID.Release")
                if(prevHistoryDocReleaseVer != releaseVer)
                  prevHistoryDocReleaseVerNum = prevHistoryDocReleaseVer.gsub(/\./, "").to_i
                  releaseVerNum = releaseVer.gsub(/\./, "").to_i
                  prevHistoryNumProp = (history == "revisions" ? "prevRevision" : "prevVersion")
                  if(prevHistoryDocReleaseVerNum > releaseVerNum)
                    prevHistoryDoc.setPropVal("#{historyProp}.#{prevHistoryNumProp}", historyKbd.getPropVal(historyProp))
                  else
                    # Doc was deleted ?? where is the version doc with the deletion ??
                    # Also possible version manually changed via KBUI in which case we don't want the previous version
                    prevHistoryDoc.setPropVal("#{historyProp}.#{prevHistoryNumProp}", 0)
                  end
                  if(historyCount > 0)
                    finalDocHistory.print(",")
                  end
                  finalDocHistory.print(prevHistoryDoc.to_json)
                  historyCount += 1
                  if(prevHistoryDocReleaseVerNum > releaseVerNum)
                    prevHistoryDoc = historyKbd
                  else
                    prevHistoryDoc = nil
                    break
                  end
                else
                  prevHistoryDoc.setPropVal("#{historyProp}.timestamp", historyKbd.getPropVal("#{historyProp}.timestamp"))
                end
              else # We've reached those docs that do not have the 'release' property. 
                prevHistoryNumProp = (history == "revisions" ? "prevRevision" : "prevVersion")
                prevHistoryDoc.setPropVal("#{historyProp}.#{prevHistoryNumProp}", 0)
                if(historyCount > 0)
                  finalDocHistory.print(",")
                end
                finalDocHistory.print(prevHistoryDoc.to_json)
                historyCount += 1
                prevHistoryDoc = nil
                # There are no more docs of interest
                break
              end
            end
          end
        else
          # If the head revision of a doc was saved with a non'/' subDocPath (targetted update), we will replace it with the full document since we don't want to lose the head revision num
          if(prevHistoryDoc.nil? and history == "revisions")
            historyKbd.setPropVal("#{historyProp}.content", doc2headVer[docId])
            historyKbd.setPropVal("revisionNum.subDocPath", "/")
            prevHistoryDoc = historyKbd
          end
        end
      else
        #@todo 
      end
    }
    if(!prevHistoryDoc.nil?)
      if(historyCount > 0)
        finalDocHistory.print(",")
      end
      finalDocHistory.print(prevHistoryDoc.to_json)
      historyCount += 1
    end
  }
  finalDocHistory.print("]")
  finalDocHistory.close()
}
historyColl2Prop.each_key { |history|
  historyProp = historyColl2Prop[history]
  historyRecs = JSON.parse(File.read("#{gbKbName}.#{history}.final"))
  count = 0
  historyRecs.each { |hrec|
    hrec.delete("_id")
    hrecKbd = BRL::Genboree::KB::KbDoc.new(hrec)
    contentDoc = hrecKbd.getPropVal("#{historyProp}.content")
    docId = contentDoc['ActionabilityDocID']['value']
    docRef = BSON::DBRef.new(gbCollName, docIds[docId])
    hrecKbd.setPropVal("#{historyProp}.docRef", docRef)
    contentDoc.delete("_id") rescue nil
    contentDoc["_id"] = docIds[docId]
    if(docId == "AC056")
      #$stdout.puts contentDoc.inspect
      #$stdout.puts hrecKbd.inspect
    end
  }
  #if(history == "versions")
  #  $stdout.puts historyRecs.inspect
  #end
  mdb.db["#{gbCollName}.#{history}"].remove({})
  #$stdout.puts historyRecs.to_json
  mdb.db["#{gbCollName}.#{history}"].insert(historyRecs)
}

$stderr.puts "Done compacting version/revision collection for #{gbCollName}"


