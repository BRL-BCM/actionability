
class GenboreeAcScoreController < ApplicationController
  include GenboreeAcDocHelper

  unloadable

  SEARCH_LIMIT = 20
  before_filter :find_project, :genboreeAcSettings
  
  respond_to :json

  # @todo change these methods to use async
  
  def saveScorerInfo()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    subdoc = params['subdoc']
    # First get the doc to see if any scorer has scored. Set up the payload accordingly
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        doc = apiReq.respBody['data']
        kbd = BRL::Genboree::KB::KbDoc.new(doc)
        #scorersProp = doc['ActionabilityDocID']['properties']['Score']['properties']['Scorers']
        scorersProp = kbd.getSubDoc('ActionabilityDocID.Score.Scorers')['Scorers']
        rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
        payload = nil
        if(scorersProp and scorersProp['items'].size > 0)
          scorer = params['scorer']
          propPath = "ActionabilityDocID.Score.Scorers.[].Scorer.{\"#{scorer}\"}"
          fieldMap[:prop] = propPath
          payload = JSON.parse(subdoc)
          #apiResult = apiPut(rsrcPath, subdoc, fieldMap)
        else
          kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
          propPath = "ActionabilityDocID.Score"
          scoreDoc = kbDoc.getSubDoc(propPath)['Score']
          scoreDoc['properties']['Scorers'] = {'items' => [ { "Scorer" => JSON.parse(subdoc) } ] }
          fieldMap[:prop] = propPath
          payload = scoreDoc
          #apiResult = apiPut(rsrcPath, JSON.generate(scoreDoc), fieldMap)
        end
        apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
        apiReq2.bodyFinish {
          headers = apiReq2.respHeaders
          status = apiReq2.respStatus
          headers['Content-Type'] = "text/plain"
          apiReq2.sendToClient( status, headers, JSON.generate(apiReq2.respBody))
        }
        apiReq2.put(rsrcPath, fieldMap, JSON.generate(payload))
        
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
  
  def saveSummaryInfo()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = {:grp => gbGroup, :kb => gbkb,  :coll => collName, :doc => docId } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        doc = apiReq.respBody['data']
        kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
        subdoc = JSON.parse(params['subdoc'])
        kbDoc.setPropVal('ActionabilityDocID.Score.Status',  subdoc['properties']['Status']['value'])
        doc['ActionabilityDocID']['properties']['Score']['properties']['Final Scores'] = subdoc['properties']['Final Scores'] 
        apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
        apiReq2.bodyFinish {
          headers = apiReq2.respHeaders
          status = apiReq2.respStatus
          headers['Content-Type'] = "text/plain"
          apiReq2.sendToClient( status, headers, JSON.generate(apiReq2.respBody))
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
  end
    
  def saveAttendeeInfo()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = {:grp => gbGroup, :kb => gbkb,  :coll => collName, :doc => docId } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        doc = apiReq.respBody['data']
        kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
        subdoc = JSON.parse(params['subdoc'])
        payload = nil
        if(kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores')['Final Scores'].nil?) 
          scoreDoc = kbDoc.getSubDoc('ActionabilityDocID.Score')
          scoreDoc['Score']['properties']['Final Scores'] = { 'properties' => {  'Metadata' => subdoc } }
          payload = kbDoc
        elsif(kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores.Metadata')['Metadata'].nil?)
          fscoreDoc = kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores')
          fscoreDoc['Final Scores']['properties']['Metadata'] = subdoc
          payload = kbDoc
        else
          rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
          fieldMap[:prop] = "ActionabilityDocID.Score.Final Scores.Metadata"
          payload = subdoc
        end
        apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
        apiReq2.bodyFinish {
          headers = apiReq2.respHeaders
          status = apiReq2.respStatus
          headers['Content-Type'] = "text/plain"
          apiReq2.sendToClient( status, headers, JSON.generate(apiReq2.respBody))
        }
        apiReq2.put(rsrcPath, fieldMap, JSON.generate(payload))
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
  
  def saveNotes()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        doc = apiReq.respBody['data']
        kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
        notes = params['notes']
        apiResult = nil
        if(kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores')['Final Scores'].nil?) 
          scoreDoc = kbDoc.getSubDoc('ActionabilityDocID.Score')
          scoreDoc['Score']['properties']['Final Scores'] = { 'properties' => {  'Metadata' => { "properties" => { "Notes" => { "value" => notes } } } } }
        elsif(kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores.Metadata')['Metadata'].nil?)
          fscoreDoc = kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores')
          fscoreDoc['Final Scores']['properties']['Metadata'] = { "properties" => { "Notes" => { "value" => notes } } }
        else
          mdDocProps = kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores.Metadata')['Metadata']['properties'] ;
          mdDocProps['Notes'] = { "value" => notes }
        end
        rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
        apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
        apiReq2.bodyFinish {
          headers = apiReq2.respHeaders
          status = apiReq2.respStatus
          apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
        }
        apiReq2.put(rsrcPath, fieldMap, JSON.generate(kbDoc))
      rescue => err
        headers = apiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        apiReq.sendToClient(status, headers, JSON.generate({"status" => {"msg" => err, "statusCode" => status}}))
      end
      
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  
  def saveUserStatus()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    status = params['status']
    gbLogin = params['gbLogin']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId } 
    
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        doc = apiReq.respBody['data']
        kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
        scorerPresent = false
        scorers = nil
        if(!kbDoc.getSubDoc('ActionabilityDocID.Score.Scorers')['Scorers'].nil?)
          scorers = kbDoc.getPropItems('ActionabilityDocID.Score.Scorers')
          scorers.each {|scorerObj|
            if(scorerObj['Scorer']['value'] == gbLogin)
              scorerPresent = true ;
              break
            end
          }
        end
        payload = nil
        if(scorerPresent)
          propPath = "ActionabilityDocID.Score.Scorers.[].Scorer.{\"#{gbLogin}\"}.Status"
          fieldMap[:prop] = propPath 
          subdoc = { "value" => status }
          rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
          payload = subdoc
        else
          if(!kbDoc.getSubDoc('ActionabilityDocID.Score.Scorers')['Scorers'].nil?)
            propPath = "ActionabilityDocID.Score.Scorers.[LAST]"
            fieldMap[:prop] = propPath 
            subdoc = { "Scorer" => { "value" => gbLogin, "properties" => { "Status" => { "value" => status }  }  }  } ;
            rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
            #apiResult = apiPut(rsrcPath, JSON.generate(subdoc), fieldMap)  
            payload = subdoc
          else
            subdoc = { "Scorer" => { "value" => gbLogin, "properties" => { "Status" => { "value" => status }  }  }  } ;
            scorers.push(subdoc)
            payload = kbDoc
          end
        end
        apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
        apiReq2.bodyFinish {
          headers = apiReq2.respHeaders
          status = apiReq2.respStatus
          apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
        }
        apiReq2.put(rsrcPath, fieldMap, JSON.generate(payload))
      rescue => err
        headers = apiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        apiReq.sendToClient(status, headers, JSON.generate({"status" => {"msg" => err, "statusCode" => status}}))
      end
      
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  
  def saveOverallStatus()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => "ActionabilityDocID.Score.Status" } 
    apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq2.bodyFinish {
      headers = apiReq2.respHeaders
      status = apiReq2.respStatus
      apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
    }
    apiReq2.put(rsrcPath, fieldMap, JSON.generate({ "value" => params['status'] }))
  end
  
  def reset()
    docId = params['docIdentifier']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    getDocAsync(docId, @acCurationColl){
      begin
        resp = nil
        kbd = BRL::Genboree::KB::KbDoc.new(@lastApiReq.respBody['data'])
        scoreProps = kbd.getPropProperties("ActionabilityDocID.Score")
        scoreProps.delete("Final Scores") rescue nil
        scoreProps.delete("Scorers") rescue nil
        apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
        apiReq.bodyFinish {
          headers = apiReq.respHeaders
          status = apiReq.respStatus
          apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
        }
        rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
        fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll =>  @acCurationColl, :doc => docId } 
        apiReq.put(rsrcPath, fieldMap, JSON.generate(kbd))
      rescue => err
        headers = @lastApiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        @lastApiReq.sendToClient(status, headers, JSON.generate({"status" => { "msg" => err, "statusCode" => 500}}))
      end
    }
  end
  
end
