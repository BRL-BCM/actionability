require 'yaml'
require 'json'
require 'uri'
require 'brl/util/util'
require 'brl/genboree/kb/kbDoc'

class GenboreeAcStageOneController < ApplicationController
  include GenboreeAcHelper

  unloadable

  SEARCH_LIMIT = 20
  before_filter :find_project
  #skip_before_filter :verify_authenticity_token
  respond_to :json


  
  def save()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    saveType  = params['saveType']
    login     = params['login']
    subdoc = params['subdoc']
    propPath = params['propPath']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult  = apiGet(rsrcPath, fieldMap)
    doc = apiResult[:respObj]['data']
    if (saveType == 'approver')
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
      doc['ActionabilityDocID']['properties']['Stage 1']['properties'] = JSON.parse(subdoc)
      apiResult = apiPut(rsrcPath, JSON.generate(doc), fieldMap)
    else
      # Get the document first
      kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
      if(kbDoc.getSubDoc('ActionabilityDocID.Stage 1.Scorers Stage1')['Scorers Stage1'].nil? or kbDoc.getPropItems('ActionabilityDocID.Stage 1.Scorers Stage1').nil? or kbDoc.getPropItems('ActionabilityDocID.Stage 1.Scorers Stage1').size == 0)
        #{ 'Scorers Stage1': { items: indScoresItems} }
        #newSubdoc = { 'Scorer Stage1' => { 'value' => login, 'properties' => JSON.parse(subdoc) } }
        newSubdoc = JSON.parse(subdoc)['Scorers Stage1']['items'][0]
        doc['ActionabilityDocID']['properties']['Stage 1']['properties']['Scorers Stage1'] = { 'items' => [newSubdoc] }
        rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
        fieldMap  = { :coll => collName, :doc => docId } 
        apiResult = apiPut(rsrcPath, JSON.generate(doc), fieldMap)
      else
        newItem = JSON.parse(subdoc)['Scorers Stage1']['items'][0]
        rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
        fieldMap[:prop] = "ActionabilityDocID.Stage 1.Scorers Stage1.[].Scorer Stage1.{\"#{login}\"}"
        #doc['ActionabilityDocID']['properties']['Stage 1']['properties']['Scorers Stage1']['items'].push( newItem )
        newSubdoc = newItem['Scorer Stage1']
        apiResult = apiPut(rsrcPath, JSON.generate(newSubdoc), fieldMap)
      end
      
    end
    respond_with({}, :status => apiResult[:status], :location => "")
  end
  
  def saveStatus()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    status    = params['status']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult  = apiGet(rsrcPath, fieldMap)
    doc = apiResult[:respObj]['data']
    kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
    kbDoc.setPropVal('ActionabilityDocID.Stage 1.Final Stage1 Report.Status', status)
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult = apiPut(rsrcPath, JSON.generate(kbDoc), fieldMap)
    respond_with({}, :status => apiResult[:status], :location => "")
  end
  
end
