require 'yaml'
require 'json'
require 'uri'
require 'brl/util/util'
require 'brl/genboree/kb/kbDoc'


class GenboreeAcStageTwoController < ApplicationController
  include GenboreeAcHelper

  unloadable

  SEARCH_LIMIT = 20
  before_filter :find_project
  
  respond_to :json


  
  def saveOutcome()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    stageTwoExists = params['stageTwoExists']
    subdoc = params['subdoc']
    propPath = params['propPath']
    # Get the document first
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult  = apiGet(rsrcPath, fieldMap)
    doc = apiResult[:respObj]['data']
    kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
    if(kbDoc.getSubDoc('ActionabilityDocID.Stage 2.Outcomes')['Outcomes'].nil? or kbDoc.getPropItems('ActionabilityDocID.Stage 2.Outcomes').empty?)
      doc['ActionabilityDocID']['properties']['Stage 2']['properties']['Outcomes'] = { "items" => [] }
      doc['ActionabilityDocID']['properties']['Stage 2']['properties']['Outcomes']['items'].push({ "Outcome" => JSON.parse(subdoc)})
      apiResult = apiPut(rsrcPath, JSON.generate(doc), fieldMap)
    else
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
      fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
      apiResult = apiPut(rsrcPath, subdoc, fieldMap)
    end
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
  def remove()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    subdoc = params['subdoc']
    propPath = params['propPath']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
    apiResult = apiDelete(rsrcPath, fieldMap)
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
  def saveCategory()
    addProjectIdToParams()
    @projectId = params['id']
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    stageTwoExists = params['stageTwoExists']
    parentExists = params['parentExists']
    itemsExist = params['itemsExist']
    itemValue = ""
    if(itemsExist == 'true')
      itemValue = params['itemValue']
    end
    subdoc = params['subdoc']
    propPath = params['propPath']
    propEls = propPath.split(".")
    prop = propEls[propEls.size-1]
    parentProp = propEls[propEls.size-2]
    propPresent = params['propPresent']
    fieldMap  = { :coll => collName, :doc => docId }
    respStatus = nil
    respObj = nil
    if(propPresent == 'false')
      # Creating property for the first time
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
      apiResult  = apiGet(rsrcPath, fieldMap)
      doc = apiResult[:respObj]['data']
      if(parentExists == 'true')
        doc['ActionabilityDocID']['properties']['Stage 2']['properties'][parentProp] = { "properties" => {} } if(!doc['ActionabilityDocID']['properties']['Stage 2']['properties'][parentProp].key?('properties'))
      else
        doc['ActionabilityDocID']['properties']['Stage 2']['properties'][parentProp] = { "properties" => {} }
      end
      newSubdoc = nil
      if(itemsExist == 'true')
        rootProp = params['rootProp']
        newSubdoc = { "items" => [{ rootProp => JSON.parse(subdoc) }] }
      else
        newSubdoc = JSON.parse(subdoc)
      end
      doc['ActionabilityDocID']['properties']['Stage 2']['properties'][parentProp]['properties'][prop] = newSubdoc
      apiResult = apiPut(rsrcPath, JSON.generate(doc), fieldMap)
      respStatus = apiResult[:status]
      updatedKBDoc = BRL::Genboree::KB::KbDoc.new(apiResult[:respObj]['data'])
      updatedSubDoc = updatedKBDoc.getSubDoc("ActionabilityDocID.Stage 2.#{parentProp}.#{prop}")
      if(itemsExist == "true")
        itemObj = updatedSubDoc[prop]['items'][0]
        respObj = { "data" => itemObj }
      else
        respObj =  { "data" => updatedSubDoc }
      end
    else
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
      if(itemsExist == 'true')
        if(itemValue and itemValue != '')
          propPath << ".[].#{params['rootProp']}.{\"#{itemValue}\"}"
        else
          $stderr.puts "Inserting section item for first time"
          propPath << ".[LAST]"
          rootProp = params['rootProp']
          subdoc = JSON.generate({ rootProp => JSON.parse(subdoc) })
        end
      end
      fieldMap[:prop] = propPath
      apiResult = apiPut(rsrcPath, subdoc, fieldMap)
      respObj = apiResult[:respObj]
      respStatus = apiResult[:status]
    end
    respond_with(respObj, :status => respStatus, :location => "")
  end
  
  def saveStatus()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    value = params['value']
    # Get the document first
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult  = apiGet(rsrcPath, fieldMap)
    doc = apiResult[:respObj]['data']
    doc['ActionabilityDocID']['properties']['Stage 2']['properties']['Status'] = { 'value' => value }
    apiResult = apiPut(rsrcPath, JSON.generate(doc), fieldMap)
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
end
