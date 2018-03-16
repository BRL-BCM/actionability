require 'yaml'
require 'json'
require 'uri'
require 'brl/util/util'
require 'brl/genboree/kb/kbDoc'

class GenboreeAcLitSearchController < ApplicationController
  include GenboreeAcDocHelper

  respond_to :json
  before_filter :find_project
  unloadable

  def saveSourceInfo()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    subdoc = JSON.parse(params['subdoc'])
    searchSourceKbDoc = BRL::Genboree::KB::KbDoc.new(subdoc)
    searchSource = subdoc['Source']['value']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    # First check if Literature Search exists in the document
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        doc = apiReq.respBody['data']
        kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
        acDocProps = kbDoc.getPropProperties('ActionabilityDocID')
        if(!acDocProps.key?('LiteratureSearch')) # LiteratureSearch does not exist yet in the document. Insert it and do a PUT
          acDocProps['LiteratureSearch'] = { "properties" => { "Status" => { "value" => "Incomplete" }, "Sources" => { "items" => [ searchSourceKbDoc ] } } }
        else # LiteratureSearch exists. 
          sources = kbDoc.getPropItems('ActionabilityDocID.LiteratureSearch.Sources')
          sourceFound = false
          sources.each { |sourceObj|
            sourceKbd = BRL::Genboree::KB::KbDoc.new(sourceObj)
            if(sourceKbd.getPropVal('Source') == searchSource)
              sourceKbd.setPropItems('Source.SearchStrings', searchSourceKbDoc.getPropItems('Source.SearchStrings'))
              sourceFound = true
              break
            end
          }
          if (!sourceFound) 
            sources.push(searchSourceKbDoc)
          end
        end
        apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
        apiReq2.bodyFinish {
          begin
            headers = apiReq2.respHeaders
            status = apiReq2.respStatus
            headers['Content-Type'] = "text/plain"
            apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
          rescue => err
            headers = apiReq2.respHeaders
            status = apiReq2.respStatus
            headers['Content-Type'] = "text/plain"
            resp = { "status" => { "statusCode" => 500, "msg" => err }}
            apiReq2.sendToClient(status, headers, JSON.generate(resp))
          end
        }
        apiReq2.put(rsrcPath, fieldMap, JSON.generate(kbDoc))
      rescue => err
        headers = apiReq.respHeaders
        headers['Content-Type'] = "text/plain"
        resp = { "status" => { "statusCode" => 500, "msg" => err }}
        apiReq.sendToClient(500, headers, JSON.generate(resp))
      end
    }
    apiReq.get(rsrcPath, fieldMap)
  end

  def saveStatus()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    status    = params['value']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => "ActionabilityDocID.LiteratureSearch.Status" }
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
    apiReq.put(rsrcPath, fieldMap, JSON.generate({ "value" => status }))
  end
  
  def remove()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    searchSource    = params['searchSource']
    searchString = params['searchString']
    origSearchStr = params['origSearchStr']
    addNew = params['addNew']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId }
    if(origSearchStr == "" and addNew == "false")
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
      apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq.bodyFinish {
        begin
          headers = apiReq.respHeaders
          status = apiReq.respStatus
          headers['Content-Type'] = "text/plain"
          doc = apiReq.respBody['data']
          kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
          sources = kbDoc.getPropItems('ActionabilityDocID.LiteratureSearch.Sources')
          sources.each { |sourceObj|
            if(sourceObj['Source']['value'] == searchSource)
              sourceKbDoc = BRL::Genboree::KB::KbDoc.new(sourceObj)
              searchStrings = sourceKbDoc.getPropItems('Source.SearchStrings')
              newSearchStrings = []
              searchStrings.each {|ss|
                if(ss['SearchString']['value'] != "")
                  newSearchStrings.push(ss)
                end
              }
              sourceKbDoc.setPropItems('Source.SearchStrings', newSearchStrings)
            end
          }
          
          apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq2.bodyFinish {
            begin
              headers = apiReq2.respHeaders
              status = apiReq2.respStatus
              headers['Content-Type'] = "text/plain"
              respBody = JSON.generate(apiReq2.respBody)
              apiReq2.sendToClient(status, headers, respBody)
            rescue => err
              headers = apiReq2.respHeaders
              status = apiReq2.respStatus
              headers['Content-Type'] = "text/plain"
              resp = { "status" => { "statusCode" => 500, "msg" => err }}
              apiReq2.sendToClient(status, headers, JSON.generate(resp))
            end
          }
          apiReq2.put(rsrcPath, fieldMap, JSON.generate(kbDoc))
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
      searchString.gsub!(/\"/, "\\\"")
      searchString.gsub!(/,/, "\\,")
      fieldMap[:prop] = "ActionabilityDocID.LiteratureSearch.Sources.[].Source.{\"#{searchSource}\"}.SearchStrings.[].SearchString.{\"#{searchString}\"}"
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
      apiReq.delete(rsrcPath, fieldMap)
    end
  end

end
