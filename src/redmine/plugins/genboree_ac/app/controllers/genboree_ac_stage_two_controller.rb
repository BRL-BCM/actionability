
class GenboreeAcStageTwoController < ApplicationController
  include GenboreeAcDocHelper

  unloadable

  SEARCH_LIMIT = 20
  before_filter :find_project
  
  respond_to :json
  
  def saveOutcome()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    stageTwoExists = params['stageTwoExists']
    subdoc = params['subdoc']
    propPath = params['propPath']
    # Get the document first
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        doc = apiReq.respBody['data']
        kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
        if(kbDoc.getSubDoc('ActionabilityDocID.Stage 2.Outcomes')['Outcomes'].nil? or kbDoc.getPropItems('ActionabilityDocID.Stage 2.Outcomes').empty?)
          stage2Doc = kbDoc.getSubDoc('ActionabilityDocID.Stage 2')['Stage 2']
          stage2Doc['properties']['Outcomes'] = JSON.parse(subdoc)
          apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq2.bodyFinish {
            headers = apiReq2.respHeaders
            status = apiReq2.respStatus
            apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
          }
          apiReq2.put(rsrcPath, fieldMap, JSON.generate(kbDoc))
        else
          # Check if the entire doc needs to be updated.
          # This is true if an existing outcome/intervention has been changed and we need to update the name wherever it is used in the document.
          if(params.key?('oiRenameReq'))
            changedNamesMap = JSON.parse(params['changedNamesMap'])
            changedNamesMap.each_key { |oldOutcome|
              newOutcome = changedNamesMap[oldOutcome]['newName']
              interventions = changedNamesMap[oldOutcome]['Interventions']
              paths = kbDoc.getMatchingPaths(/Outcomes$/)
              paths.each { |pp|
                next if(pp =~ /Stage 2\.Outcomes$/)
                items = kbDoc.getPropItems(pp)
                if(items)
                  items.each { |item|
                    kbd =  BRL::Genboree::KB::KbDoc.new(item)
                    if(kbd.getPropVal("Outcome") == oldOutcome && oldOutcome != newOutcome)
                      kbd.setPropVal("Outcome", newOutcome)
                    end
                    if(interventions.size > 0 and !kbd.getSubDoc('Outcome.Interventions')['Interventions'].nil?)
                      intItems = kbd.getPropItems('Outcome.Interventions')
                      if(intItems)
                        intItems.each { |intDoc|
                          kbIntDoc =  BRL::Genboree::KB::KbDoc.new(intDoc)
                          intName = kbIntDoc.getPropVal('Intervention')
                          if(interventions.key?(intName))
                            kbIntDoc.setPropVal('Intervention', interventions[intName])
                          end
                        }
                      end
                    end
                  }
                end
              }
            }
            kbDoc.setPropItems("ActionabilityDocID.Stage 2.Outcomes", JSON.parse(subdoc)['items'])
            apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
            apiReq2.bodyFinish {
              headers = apiReq2.respHeaders
              status = apiReq2.respStatus
              apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
            }
            apiReq2.put(rsrcPath, fieldMap, JSON.generate(kbDoc))
          else
            rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
            fieldMap[:prop] = propPath 
            apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
            apiReq2.bodyFinish {
              headers = apiReq2.respHeaders
              status = apiReq2.respStatus
              apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
            }
            apiReq2.put(rsrcPath, fieldMap, subdoc)
          end
        end
      rescue => err
        headers = apiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        resp = { "status" => { "statusCode" => 500, "msg" => err }}
        $stderr.puts "TRACE:\n#{err.backtrace.join("\n")}"
        apiReq.sendToClient(status, headers, JSON.generate(resp))
      end
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  
  def remove()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    subdoc = params['subdoc']
    propPath = params['propPath']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => propPath }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
    }
    apiReq.delete(rsrcPath, fieldMap)
  end
  
  def saveCategory()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    stageTwoExists = params['stageTwoExists']
    parentExists = params['parentExists']
    itemsExist = params['itemsExist']
    subdoc = params['subdoc']
    propPath = params['propPath']
    propEls = propPath.split(".")
    prop = propEls[propEls.size-1]
    parentProp = propEls[propEls.size-2]
    propPresent = params['propPresent']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    if(propPresent == 'false')
      # Creating property for the first time
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
      fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId }
      apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq.bodyFinish {
        begin
          doc = apiReq.respBody['data']
          if(parentExists == 'true')
            doc['ActionabilityDocID']['properties']['Stage 2']['properties'][parentProp] = { "properties" => {} } if(!doc['ActionabilityDocID']['properties']['Stage 2']['properties'][parentProp].key?('properties'))
          else
            doc['ActionabilityDocID']['properties']['Stage 2']['properties'][parentProp] = { "properties" => {} }
          end
          doc['ActionabilityDocID']['properties']['Stage 2']['properties'][parentProp]['properties'][prop] = JSON.parse(subdoc)
          apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq2.bodyFinish {
            headers = apiReq2.respHeaders
            status = apiReq2.respStatus
            headers['Content-Type'] = "text/plain"
            updatedKBDoc = BRL::Genboree::KB::KbDoc.new(apiReq2.respBody['data'])
            updatedSubDoc = updatedKBDoc.getSubDoc("ActionabilityDocID.Stage 2.#{parentProp}.#{prop}")
            respObj = ( itemsExist == 'true' ? { "data" => updatedSubDoc[prop] } : { "data" => updatedSubDoc } ) 
            apiReq.sendToClient(status, headers, JSON.generate(respObj))
          }
          apiReq2.put(rsrcPath, fieldMap, JSON.generate(doc))
        rescue => err
          headers = apiReq.respHeaders
          status = apiReq.respStatus
          headers['Content-Type'] = "text/plain"
          resp = { "status" => { "statusCode" => 500, "msg" => err }}
          apiReq.sendToClient(status, headers, JSON.generate(resp))
        end
      }
      apiReq.get(rsrcPath, fieldMap)
    else
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
      fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => propPath }
      apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq.bodyFinish {
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
      }
      apiReq.put(rsrcPath, fieldMap, subdoc)
    end
  end
  
  def saveStatus()
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    value = params['value']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => "ActionabilityDocID.Stage 2.Status" } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
    }
    apiReq.put(rsrcPath, fieldMap, JSON.generate({"value" => value}))
  end
  
end
