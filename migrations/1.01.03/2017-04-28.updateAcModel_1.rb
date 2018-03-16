#!/usr/bin/env ruby

# Script to update/migrate all Actionability docs to update 'Relative Risk', 'Expressivity Notes' and 'Clinical Escape Chance' to be items based. 
# The script needs to be run for both the 'working' KB as well as the 'release KB'


require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/rest/apiCaller'
require "genboreeTools"

def setAutoIDToEmpty(atsDoc)
  if(atsDoc['items'] and atsDoc['items'].size > 0)
    items = atsDoc['items']
    items.each { |ats|
      kbd = BRL::Genboree::KB::KbDoc.new(ats)
      kbd.setPropVal('RecommendationID', '')
    }
  end
end

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
## Change the 3 properties listed above to be items based.
# Relative Risk
model['properties'][5]['properties'][5]['properties'][3] = {"name"=>"Relative Risks", "items"=>[{"name"=>"Relative Risk", "category"=>false, "fixed"=>false, "properties"=>[{"name"=>"Key Text", "required"=>true, "domain"=>"enum(>3, 2-3, <2, Unknown)"}, { "name" => "Notes"}, {"name"=>"References", "items"=>[{"name"=>"Reference", "required"=>true, "domain"=>"url", "identifier"=>true, "index"=>true, "unique"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}, {"name"=>"Additional Tiered Statements", "items"=>[{"name"=>"RecommendationID", "properties"=>[{"name"=>"Recommendation"}, {"name"=>"Tier", "domain"=>"enum(1,2,3,4,5,Not provided)"}, {"name"=>"References", "items"=>[{"name"=>"Reference", "required"=>true, "domain"=>"url", "identifier"=>true, "index"=>true, "unique"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}], "domain"=>"autoID(REC, increment[3],,)", "identifier"=>true, "index"=>true, "unique"=>true}], "fixed"=>true, "domain"=>"[valueless]"}, {"name"=>"Tier", "domain"=>"enum(1,2,3,4,5,Not provided)"}], "domain"=>"autoID(RR, increment[3],,)", "identifier"=>true, "index"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}
# Expressivity Notes
model['properties'][5]['properties'][5]['properties'][4] = {"name"=>"Expressivity Notes", "items"=>[{"name"=>"Expressivity Note", "category"=>false, "fixed"=>false, "properties"=>[{"name"=>"Key Text", "required"=>true}, {"name"=>"References", "items"=>[{"name"=>"Reference", "required"=>true, "domain"=>"url", "identifier"=>true, "index"=>true, "unique"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}, {"name"=>"Additional Tiered Statements", "items"=>[{"name"=>"RecommendationID", "properties"=>[{"name"=>"Recommendation"}, {"name"=>"Tier", "domain"=>"enum(1,2,3,4,5,Not provided)"}, {"name"=>"References", "items"=>[{"name"=>"Reference", "required"=>true, "domain"=>"url", "identifier"=>true, "index"=>true, "unique"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}], "domain"=>"autoID(REC, increment[3],,)", "identifier"=>true, "index"=>true, "unique"=>true}], "fixed"=>true, "domain"=>"[valueless]"}, {"name"=>"Tier", "domain"=>"enum(1,2,3,4,5,Not provided)"}], "domain"=>"autoID(EN, increment[3],,)", "identifier"=>true, "index"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}
# Condition Escape Detection
model['properties'][5]['properties'][7]['properties'][0] = {"name"=>"Chances to Escape Clinical Detection", "items"=>[{"name"=>"Chance to Escape Clinical Detection", "category"=>false, "fixed"=>false, "properties"=>[{"name"=>"Key Text", "required"=>true}, {"name"=>"References", "items"=>[{"name"=>"Reference", "required"=>true, "domain"=>"url", "identifier"=>true, "index"=>true, "unique"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}, {"name"=>"Additional Tiered Statements", "items"=>[{"name"=>"RecommendationID", "properties"=>[{"name"=>"Recommendation"}, {"name"=>"Tier", "domain"=>"enum(1,2,3,4,5,Not provided)"}, {"name"=>"References", "items"=>[{"name"=>"Reference", "required"=>true, "domain"=>"url", "identifier"=>true, "index"=>true, "unique"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}], "domain"=>"autoID(REC, increment[3],,)", "identifier"=>true, "index"=>true, "unique"=>true}], "fixed"=>true, "domain"=>"[valueless]"}, {"name"=>"Tier", "domain"=>"enum(1,2,3,4,5,Not provided)"}], "domain"=>"autoID(CDEC, increment[3],,)", "identifier"=>true, "index"=>true}], "category"=>true, "fixed"=>true, "domain"=>"[valueless]"}
#puts JSON.pretty_generate(model['properties'][5]['properties'][0])
# Update model
apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?unsafeForceModelUpdate=true")
apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName }, model.to_json )
modelUpdated= true
if(apiCaller.succeeded?)
  $stderr.puts "MODEL UPDATE SUCCESSFUL."
else
  $stderr.puts "MODEL_UPDATE_FAILED: #{apiCaller.respBody.inspect}"
  modelUpdated = false
end



if(modelUpdated)
  docsReportInfo = {}
  docs.each { |doc|
    kbd = BRL::Genboree::KB::KbDoc.new(doc)
    docId = kbd.getPropVal('ActionabilityDocID')
    $stderr.puts "Checking doc: #{docId.inspect}"
    stage2Props = kbd.getPropProperties('ActionabilityDocID.Stage 2')
    if(stage2Props.key?('Threat Materialization Chances') or stage2Props.key?('Condition Escape Detection') or stage2Props.key?('Acceptability of Intervention'))
      $stderr.puts "DOC_UPDATE_REQUIRED"
      docsReportInfo[docId] = { :updateReq => "UPDATE REQUIRED" }
      if(stage2Props.key?('Threat Materialization Chances'))
        tmcProps = kbd.getPropProperties('ActionabilityDocID.Stage 2.Threat Materialization Chances')
        if(tmcProps.key?('Relative Risk'))
          rrValueDoc = tmcProps['Relative Risk'].deep_clone
          rrValueDoc['value'] = ""
          if(rrValueDoc['properties'].key?('Additional Tiered Statements'))
            setAutoIDToEmpty(rrValueDoc['properties']['Additional Tiered Statements'])
          end
          tmcProps.delete('Relative Risk')
          tmcProps['Relative Risks'] = { "items" => [ { "Relative Risk" => rrValueDoc } ] }
        end
        if(tmcProps.key?('Expressivity Notes'))
          enValueDoc = tmcProps['Expressivity Notes'].deep_clone
          enValueDoc['value'] = ""
          if(enValueDoc['properties'].key?('Notes'))
            enValueDoc['properties'].delete('Notes')
          end
          if(enValueDoc['properties'].key?('Additional Tiered Statements'))
            setAutoIDToEmpty(enValueDoc['properties']['Additional Tiered Statements'])
          end
          tmcProps.delete('Expressivity Notes')
          tmcProps['Expressivity Notes'] = { "items" => [ { "Expressivity Note" => enValueDoc } ] }
        end
      end
      if(stage2Props.key?('Condition Escape Detection'))
        cedProps = kbd.getPropProperties('ActionabilityDocID.Stage 2.Condition Escape Detection')
        if(cedProps.key?('Chance to Escape Clinical Detection'))
          cecdValueDoc = cedProps['Chance to Escape Clinical Detection'].deep_clone
          cecdValueDoc['value'] = ""
          if(cecdValueDoc['properties'].key?('Notes'))
            cecdValueDoc['properties'].delete("Notes")
          end
          if(cecdValueDoc['properties'].key?('Additional Tiered Statements'))
            setAutoIDToEmpty(cecdValueDoc['properties']['Additional Tiered Statements'])
          end
          cedProps.delete('Chance to Escape Clinical Detection')
          cedProps['Chances to Escape Clinical Detection'] = { "items" => [ { "Chance to Escape Clinical Detection" => cecdValueDoc } ] }
        end
      end
      # Set Tier for all natures of intervention to 'Not provided'
      if(stage2Props.key?('Acceptability of Intervention'))
        aiProps = kbd.getPropProperties('ActionabilityDocID.Stage 2.Acceptability of Intervention')
        if(aiProps.key?('Natures of Intervention'))
          nois = aiProps['Natures of Intervention']['items']
          nois.each { |noiObj|
            noikbd = BRL::Genboree::KB::KbDoc.new(noiObj)
            noiProps = noikbd.getPropProperties('Nature of Intervention')
            if(noiProps.key?('Tier'))
              noikbd.setPropVal('Nature of Intervention.Tier', "Not provided")
            end
            if(noiProps.key?('Additional Tiered Statements'))
              noiats = noiProps['Additional Tiered Statements']['items']
              noiats.each { |atsObj|
                atskbd = BRL::Genboree::KB::KbDoc.new(atsObj)
                atsProps = atskbd.getPropProperties('RecommendationID')
                if(atsProps.key?('Tier'))
                  atskbd.setPropVal('RecommendationID.Tier', "Not provided")
                end
              }
            end
          }
        end
      end
      docsReportInfo[docId][:updateDone] = "OK"
      apiCaller.setRsrcPath("/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}")
      apiCaller.put( {:grp => gbGroup, :kb => gbKb, :coll => collName, :doc => docId }, kbd.to_json )
      if(apiCaller.succeeded?)
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



