
module GenboreeAcDocHelper
  # @todo do this dynamically by looking up the model?. This is not the best way to do this!
  AUTOID_PROPS = [
                    'ActionabilityDocID.Stage 2.Effectiveness of Intervention.Patient Managements',
                    'ActionabilityDocID.Stage 2.Effectiveness of Intervention.Surveillances',
                    'ActionabilityDocID.Stage 2.Effectiveness of Intervention.Family Managements',
                    'ActionabilityDocID.Stage 2.Effectiveness of Intervention.Circumstances to Avoid',
                    'ActionabilityDocID.Stage 2.Threat Materialization Chances.Penetrances'
                  ]
  
  def self.included(includingClass)
    includingClass.send(:include, KbHelpers::KbProjectHelper)
    includingClass.send(:include, GenboreeAcHelper)
    includingClass.send(:include, GenboreeAcAsyncHelper)
  end

  def self.extended(extendingObj)
    extendingObj.send(:extend, KbHelpers::KbProjectHelper)
    extendingObj.send(:extend, GenboreeAcHelper)
    extendingObj.send(:extend, GenboreeAcAsyncHelper)
  end
  
  # Other helpers used by genboree_ac_doc_controller
  # Used when the "Status' for a document is set to 'Released'
  # Document is uploaded to the 'Release' database along with all it's references.
  # The name of the collections for both the actionability and the references collection MUST be the same.
  def initUploadReleaseDoc( kbDoc )
    begin
      # Get the autoid counter value. We may need to 'reserve' an id for this document
      rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/model/prop/ActionabilityDocID/autoIDs?"
      kbDoc = setAutoIdsToEmpty(kbDoc)
      targetHost = getHost()
      apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq.bodyFinish {
        begin
          kbd = BRL::Genboree::KB::KbDoc.new(apiReq.respBody['data'])
          currCounterVal = kbd.getPropVal('PropPath.Additional Information.Counters.Type.Value').to_i
          #$stderr.debugPuts(__FILE__, __method__, "DEBUG", "currCounterVal:\n#{currCounterVal.inspect}")
          docIdCounter = kbDoc.getPropVal('ActionabilityDocID').gsub(/^AC/, "").to_i
          #$stderr.debugPuts(__FILE__, __method__, "DEBUG", "docIdCounter:\n#{docIdCounter.inspect}")
          if( docIdCounter > currCounterVal )
            incrementBy = docIdCounter - currCounterVal
            incrementAutoIDCounterForColl(incrementBy, @acCurationColl, 'ActionabilityDocID')
            uploadReleaseDoc(kbDoc)
          else # We are good. We can do the insert without resevring the auto ids 
            uploadReleaseDoc(kbDoc)
          end
          # Now we upload the ref docs.
          # Same step as before: reserve the autoIDs if required and then do the upload
          getDocRefsAsync(kbDoc, @acRefColl, opts={ :replaceWithNums => false}) { |refDocs|
            begin
              loadAcRefDocs(refDocs) if(refDocs and !refDocs.empty?)
              sendResp(apiReq, { }, 200)
            rescue  => err
              $stderr.debugPuts(__FILE__, __method__, "ERROR", err)
              sendResp(@lastApiReq, { "status" => { "msg" => err } }, 500)
            end
          }
          
        rescue => err
          sendResp(apiReq, { "status" => { "msg" => err } }, 500)
        end
      }
      apiReq.get(rsrcPath, { :coll => @acCurationColl })
      fieldMap  = { :coll => @acRefColl, :doc => kbDoc.getPropVal('ActionabilityDocID') } 
      kbDoc = setAutoIdsToEmpty(kbDoc)
      
    rescue => err
      $stderr.debugPuts(__FILE__, __method__, "ERROR", err)
      sendResp(@lastApiReq, { "status" => { "msg" => err } }, 500)
    end
  end
  
  def setAutoIdsToEmpty(kbDoc)
    AUTOID_PROPS.each { |propPath|
      items = kbDoc.getPropItems(propPath)
      if( items and items.size > 0 )
        items.each {|item|
          rootProp = item.keys[0]
          item[rootProp]['value'] = ""
        }
      end
    }
    return kbDoc
  end
  
  def uploadReleaseDoc(kbDoc)
    rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/docs?"
    targetHost = getHost()
    payload = [kbDoc]
    apiResult = apiPut(rsrcPath, JSON.generate(payload), { :coll => @acCurationColl })
    #$stderr.debugPuts(__FILE__, __method__, "DEBUG", "apiresult:\n#{apiResult.inspect}")
    if( apiResult[:status] != 200 )
      raise apiResult[:respObj]['status']['msg']
    end
  end

  def incrementAutoIDCounterForColl(incrementBy, coll, idProp)
    rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/model/prop/#{idProp}/autoIDs?amount=#{incrementBy}"
    targetHost = getHost()
    apiResult = apiPut(rsrcPath, "", { :coll => coll })
    #$stderr.debugPuts(__FILE__, __method__, "DEBUG", "apiresult:\n#{apiResult.inspect}")
    if( apiResult[:status] != 200 )
      raise apiResult[:respObj]['status']['msg']
    end
  end
  
  def loadAcRefDocs(refDocs)
    # Get the last ref id. We may need to reserve the autoIDs in the target collection
    maxId = 0
    refDocs.each {|refDoc|
      kbd = BRL::Genboree::KB::KbDoc.new(refDoc)
      refId = kbd.getPropVal('Reference').gsub(/^RF/, "").to_i
      if( refId > maxId )
        maxId = refId
      end
    }
    targetHost = getHost()
    apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq2.bodyFinish {
      begin
        kbd = BRL::Genboree::KB::KbDoc.new(apiReq2.respBody['data'])
        currCounterVal = kbd.getPropVal('PropPath.Additional Information.Counters.Type.Value').to_i
        if( maxId > currCounterVal ) # We'll need to reserve the autoIds for the target ref collection
          incrementBy = maxId - currCounterVal
          incrementAutoIDCounterForColl(incrementBy, @acRefColl, 'Reference')
        end
        uploadRefDocs(refDocs)
        sendResp(apiReq2, {}, 200)
      rescue => err
        sendResp(apiReq2, { "status" => { "msg" => err } }, 500)
      end
    }
    rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/model/prop/Reference/autoIDs?"
    apiReq2.get(rsrcPath, { :coll => @acRefColl })
  end
  
  def uploadRefDocs(refDocs)
    rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/docs?"
    targetHost = getHost()
    apiResult = apiPut(rsrcPath, JSON.generate(refDocs), { :coll => @acRefColl })
    if( apiResult[:status] != 200 )
      raise apiResult[:respObj]['status']['msg']
    end
  end
  
  def sendResp(apiReqObj, respBody, status)
    headers = apiReqObj.respHeaders
    headers['Content-Type'] = "text/plain"
    apiReqObj.sendToClient( status, headers, JSON.generate( respBody ) )
  end
  
  def constructSyndromeRespObj(syndromeDoc)
    #$stderr.puts "syndromeDoc:\n#{JSON.pretty_generate(syndromeDoc)}"
    syndrome = syndromeDoc['value']
    orphs = []
    omims = []
    acrs = []
    overview = ""
    props = syndromeDoc['properties']
    if( props.key?('OmimIDs') )
      omimItems = props['OmimIDs']['items']
      omimItems.each {|oi|
        omims.push(oi['OmimID']['value'])  
      }
    end
    if( props.key?('OrphanetIDs') )
      orphItems = props['OrphanetIDs']['items']
      orphItems.each {|oi|
        orphs.push(oi['OrphanetID']['value'])  
      }
    end
    if( props.key?('Acronyms') )
      acrItems = props['Acronyms']['items']
      acrItems.each {|acr|
        acrs.push(acr['Acronym']['value'])  
      }
    end
    if( props.key?('Overview') )
      overview = props['Overview']['value']
    end
    respData = {}
    respData['syndrome'] = syndrome
    respData['orphanet'] = orphs
    respData['omim'] = omims
    respData['aliases'] = acrs
    respData['overview'] = overview
    resp = {}
    resp['data'] = respData
    return resp
  end
  
  def constructStatusRespObj(statusDoc, fieldMap)
    resp = { "data" => {} }
    kbDoc = BRL::Genboree::KB::KbDoc.new(statusDoc)
    userRec = getGbAccount(kbDoc.getPropVal('versionNum.author'))
    resp['data']['lastEditedBy'] = "#{userRec['firstName']} #{userRec['lastName']}"
    actualKbDoc = BRL::Genboree::KB::KbDoc.new(kbDoc.getPropVal('versionNum.content'))
    resp['data']['status'] = actualKbDoc.getPropVal('ActionabilityDocID.Status')
    return resp
  end
  
end
