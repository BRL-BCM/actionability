require 'yaml'
require 'json'
require 'uri'
require 'brl/util/util'
require 'brl/genboree/kb/kbDoc'

class GenboreeAcStageOneController < ApplicationController
  include GenboreeAcDocHelper
  unloadable
  SEARCH_LIMIT = 20
  before_filter :find_project
  respond_to :json
  
  def save()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    saveType  = params['saveType']
    login     = params['login']
    subdoc = params['subdoc']
    propPath = params['propPath']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        doc = apiReq.respBody['data']
        payload = nil
        if(saveType == 'approver')
          rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
          fieldMap[:prop] = "ActionabilityDocID.Stage 1"
          payload = { "properties" => JSON.parse(subdoc) }
        else
          kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
          if(kbDoc.getSubDoc('ActionabilityDocID.Stage 1.Scorers Stage1')['Scorers Stage1'].nil? or kbDoc.getPropItems('ActionabilityDocID.Stage 1.Scorers Stage1').nil? or kbDoc.getPropItems('ActionabilityDocID.Stage 1.Scorers Stage1').size == 0)
            newSubdoc = JSON.parse(subdoc)['Scorers Stage1']['items'][0]
            doc['ActionabilityDocID']['properties']['Stage 1']['properties']['Scorers Stage1'] = { 'items' => [newSubdoc] }
            rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
            payload = doc
          else
            newItem = JSON.parse(subdoc)['Scorers Stage1']['items'][0]
            rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
            fieldMap[:prop] = "ActionabilityDocID.Stage 1.Scorers Stage1.[].Scorer Stage1.{\"#{login}\"}"
            newSubdoc = newItem['Scorer Stage1']
            payload = newSubdoc
          end
        end
        apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
        apiReq2.bodyFinish {
          headers = apiReq2.respHeaders
          status = apiReq2.respStatus
          headers['Content-Type'] = "text/plain"
          apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
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
  
  def saveStatus()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    status    = params['status']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => "ActionabilityDocID.Stage 1.Final Stage1 Report.Status" } 
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
    apiReq.put(rsrcPath, fieldMap, JSON.generate({"value" => status}))
  end
  
end
