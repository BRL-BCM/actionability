
class GenboreeAcHistoryController < ApplicationController
  include GenboreeAcDocHelper

  unloadable

  SEARCH_LIMIT = 20
  before_filter :find_project
  
  respond_to :json

  def show()
    propPath = params['propPath']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}/revs"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => propPath } 
    
    #apiResult  = apiGet(rsrcPath, fieldMap)
    #jsonResp = JSON.generate(apiResult[:respObj])
    #render(:json => jsonResp, :content_type => "text/html", :status => apiResult[:status])
    
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        respBody = JSON.generate(apiReq.respBody)
        apiReq.sendToClient(status, headers, respBody)
      rescue => err
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        resp = { "status" => { "statusCode" => 500, "msg" => err }}
        apiReq.sendToClient(status, headers, JSON.generate(resp))
      end
    }
    apiReq.get(rsrcPath, fieldMap)
    
  end
  
  def diffOutcome()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    propPath = params['propPath']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}/revs"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    rev2Interventions = JSON.parse(params['rev2Content']) ;
    olderRev, latestRev = returnNewerAndOlderRevisions(rev2Interventions)
    # Diff the 'full' name first
    latestOutcomeFullName = rev2Interventions[latestRev]['FullName']
    latestOutcomeFullName = "" if(latestOutcomeFullName.nil?)
    olderOutcomeFullName = rev2Interventions[olderRev]['FullName']
    olderOutcomeFullName = "" if(olderOutcomeFullName.nil?)
    diffByWord = Differ.diff_by_word(latestOutcomeFullName, olderOutcomeFullName)  # Latest version first
    diffedHtml = "<b>Full Outcome Name</b>:<br>"
    diffedHtml << diffByWord.format_as(:html)
    diffedHtml << "<br><b>Interventions</b>:<br>"
    latestInterventionsStr = constructInterventionList(rev2Interventions[latestRev]['Interventions'])
    olderInterventionsStr = constructInterventionList(rev2Interventions[olderRev]['Interventions'])
    # Diff the list of intervention next
    diffByWord = Differ.diff_by_word(latestInterventionsStr, olderInterventionsStr)  # Latest version first
    diffedHtml << diffByWord.format_as(:html)
    respJson = { "data" => diffedHtml }
    render(:json => JSON.generate(respJson), :content_type => "text/html", :status => 200)
  end
  
  def diffBaseSection()
    propPath = params['propPath']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}/revs"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    rev2Content = JSON.parse(params['rev2Content']) ;
    olderRev, latestRev = returnNewerAndOlderRevisions(rev2Content)
    latestPropVals = rev2Content[latestRev]
    olderPropVals = rev2Content[olderRev]
    respHash = constructRespHash(latestPropVals, olderPropVals)
    respHash.each_key { |prop|
      latestPropVal = ""
      olderPropVal = ""
      addField = false
      diffStr = ""
      if( prop =~ /^AdditionalFields/ )
        addField = true
        prop = prop.gsub(/^AdditionalFields-/, "")
        latestPropVal = rev2Content[latestRev]['Additional Fields'][prop]
        olderPropVal = rev2Content[olderRev]['Additional Fields'][prop]
        diffStr = generateDiffForPropVals(prop, latestPropVal, olderPropVal)
      elsif( prop == 'Additional Tiered Statements')
        diffStr = generateDiffForATS(rev2Content[latestRev][prop]['items'], rev2Content[olderRev][prop]['items'])
      else
        latestPropVal = rev2Content[latestRev][prop]
        olderPropVal = rev2Content[olderRev][prop]
        diffStr = generateDiffForPropVals(prop, latestPropVal, olderPropVal)
      end
      if( addField )
        if( respHash.key?("Additional Fields") )
          respHash["Additional Fields"][prop] = diffStr 
        else
          respHash["Additional Fields"] = { prop => diffStr }
        end
      else
        respHash[prop] = diffStr
      end
    }
    cleanRespHash(respHash)
    respJson = { "data" => respHash }
    render(:json => JSON.generate(respJson), :content_type => "text/html", :status => 200)
  end
  
  # Helper methods
  
  def generateDiffForATS(litems, oitems)
    oitemHash = {}
    litemHash = {}
    # We need to create a lookup hash for both new and old revisions
    litems.each { |atsObj|
      atsDoc = BRL::Genboree::KB::KbDoc.new(atsObj)
      recId = atsDoc.getPropVal('RecommendationID')
      stmt = atsDoc.getPropVal('RecommendationID.Recommendation')
      tier = atsDoc.getPropVal('RecommendationID.Tier')
      references = atsDoc.getPropItems('RecommendationID.RefStrings')
      refs = []
      if(references)
        refs = references
      end
      litemHash[recId] = { :stmt => stmt, :tier => tier, :refs => refs.join(", ") }
    }
    oitems.each { |atsObj|
      atsDoc = BRL::Genboree::KB::KbDoc.new(atsObj)
      recId = atsDoc.getPropVal('RecommendationID')
      stmt = atsDoc.getPropVal('RecommendationID.Recommendation')
      tier = atsDoc.getPropVal('RecommendationID.Tier')
      references = atsDoc.getPropItems('RecommendationID.RefStrings')
      refs = []
      if(references)
        #$stderr.puts "References:\n#{references.inspect}"
        refs = references
      end
      oitemHash[recId] = { :stmt => stmt, :tier => tier, :refs => refs.join(", ") }
    }
    # Go through the newer list and see if the older list has a statement with the same id. If it does not, use "", it'll be shown as newly added
    retVal = []
    recIdCovered = {}
    litems.each { |atsObj|
      atsDoc = BRL::Genboree::KB::KbDoc.new(atsObj)
      recId = atsDoc.getPropVal('RecommendationID')
      recIdCovered[recId] = true
      lStmt = litemHash[recId][:stmt]
      lTier = litemHash[recId][:tier]
      lRefs = litemHash[recId][:refs]
      if(oitemHash.key?(recId))
        oStmt = oitemHash[recId][:stmt]
        oTier = oitemHash[recId][:tier]
        oRefs = oitemHash[recId][:refs]
      else
        oStmt = ""
        oTier = ""
        oRefs = ""
      end
      
      diffStmt = Differ.diff_by_word(lStmt, oStmt)  # Latest version first
      diffTier = Differ.diff_by_word(lTier, oTier)  # Latest version first
      diffRefs = Differ.diff_by_word(lRefs, oRefs)  # Latest version first
      retVal << { "diffStmt" => diffStmt.format_as(:html), "diffTier" => diffTier.format_as(:html), "diffRefs" => diffRefs.format_as(:html) }
    }
    # Go through the older list and check if something was deleted and is absent in the newer list. This will be shown as stricken off.
    oitems.each { |atsObj|
      atsDoc = BRL::Genboree::KB::KbDoc.new(atsObj)
      recId = atsDoc.getPropVal('RecommendationID')
      if(recIdCovered.key?(recId))
        next
      end
      oStmt = oitemHash[recId][:stmt]
      oTier = oitemHash[recId][:tier]
      oRefs = oitemHash[recId][:refs]
      diffStmt = Differ.diff_by_word("", oStmt)  # Latest version first
      diffTier = Differ.diff_by_word("", oTier)  # Latest version first
      diffRefs = Differ.diff_by_word("", oRefs)  # Latest version first
      retVal << { "diffStmt" => diffStmt.format_as(:html), "diffTier" => diffTier.format_as(:html), "diffRefs" => diffRefs.format_as(:html) }
    }
    return retVal
  end
  
  def revertOutcome()
    outcome = params['outcome']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    collName  = params['acCurationColl']
    docId = params['docIdentifier']
    subdoc = params['subdoc']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    propPath = "ActionabilityDocID.Stage 2.Outcomes.[].Outcome.{\"#{outcome}\"}"
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => propPath } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        respBody = JSON.generate(apiReq.respBody)
        apiReq.sendToClient(status, headers, respBody)
      rescue => err
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        resp = { "status" => { "statusCode" => 500, "msg" => err }}
        apiReq.sendToClient(status, headers, JSON.generate(resp))
      end
    }
    apiReq.put(rsrcPath, fieldMap, subdoc)
  end
  
  def revertStage2BaseSection()
    outcome = params['outcome']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    collName  = params['acCurationColl']
    docId = params['docIdentifier']
    subdoc = params['subdoc']
    propPath = params['propPath']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => propPath }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        respBody = JSON.generate(apiReq.respBody)
        apiReq.sendToClient(status, headers, respBody)
      rescue => err
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        resp = { "status" => { "statusCode" => 500, "msg" => err }}
        apiReq.sendToClient(status, headers, JSON.generate(resp))
      end
    }
    apiReq.put(rsrcPath, fieldMap, subdoc)
  end
  
  
  def cleanRespHash(respHash)
    respHash.each_key { |key|
      respHash.delete(key) if(key =~ /^AdditionalFields-/)  
    }
  end
  
  
  
  def generateDiffForPropVals(prop, latestPropVal, olderPropVal)
    latestStr = ""
    olderStr = ""
    diffedHtml = ""
    if(prop == 'Outcomes' or prop == 'References')
      latestStr = latestPropVal ? latestPropVal.join(", ") : ""
      olderStr = olderPropVal ? olderPropVal.join(", ") : ""
    else
      latestStr = latestPropVal ? latestPropVal : ""
      olderStr = olderPropVal ? olderPropVal : ""
    end
    diffByWord = Differ.diff_by_word(latestStr, olderStr)  # Latest version first
    diffedHtml = diffByWord.format_as(:html)
  end
  
  
  
  def returnNewerAndOlderRevisions(obj)
    latestRev = nil
    olderRev = nil
    obj.each_key { |revNo|
      if(latestRev.nil?)
        latestRev = revNo
        olderRev = revNo
      else
        if(latestRev < revNo)
          latestRev = revNo
        else
          olderRev = revNo
        end
      end
    }
    return [olderRev, latestRev]
  end
  
  def constructInterventionList(interventions)
    list = []
    interventions.each {|interventionObj|
      kbDoc = BRL::Genboree::KB::KbDoc.new(interventionObj)
      str = kbDoc.getPropVal('Intervention')
      list.push(str)
    }
    if(!list.empty?)
      retVal = list.join("<br>")
    end
    return retVal
  end
  
  def constructRespHash(latestPropVals, olderPropVals)
    respHash = {}
    latestPropVals.each_key { |prop|
      if(prop == 'ReferencesOrigURLs')
        next
      end
      if( prop == 'Additional Fields' )
        addProps = latestPropVals[prop]
        addProps.keys.each {|addProp|
          respHash["AdditionalFields-#{addProp}"] = nil  
        }
      else
        respHash[prop] = nil  
      end
    }
    olderPropVals.each_key { |prop|
      if(prop == 'ReferencesOrigURLs')
        next
      end
      if( prop == 'Additional Fields' )
        addProps = latestPropVals[prop]
        addProps.keys.each {|addProp|
          respHash["AdditionalFields-#{addProp}"] = nil  
        }
      else
        respHash[prop] = nil  
      end
    }
    return respHash
  end
  
  
  
  
end
