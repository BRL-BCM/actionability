require 'yaml'
require 'json'
require 'uri'
require 'brl/util/util'
require 'brl/genboree/kb/kbDoc'

class GenboreeAcScoreController < ApplicationController
  include GenboreeAcHelper

  unloadable

  SEARCH_LIMIT = 20
  before_filter :find_project
  
  respond_to :json


  
  def saveScorerInfo()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    subdoc = params['subdoc']
    # First get the doc to see if any scorer has scored. Set up the payload accordingly
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult = apiGet(rsrcPath, fieldMap)
    doc = apiResult[:respObj]['data']
    scorersProp = doc['ActionabilityDocID']['properties']['Score']['properties']['Scorers']
    if(scorersProp and scorersProp['items'].size > 0)
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
      scorer = params['scorer']
      propPath = "ActionabilityDocID.Score.Scorers.[].Scorer.{\"#{scorer}\"}"
      fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
      apiResult = apiPut(rsrcPath, subdoc, fieldMap)
    else
      doc['ActionabilityDocID']['properties']['Score']['properties']['Scorers'] = {'items' => [ { "Scorer" => JSON.parse(subdoc) } ] }
      apiResult = apiPut(rsrcPath, JSON.generate(doc), fieldMap)
    end
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
  def saveSummaryInfo()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult = apiGet(rsrcPath, fieldMap)
    doc = apiResult[:respObj]['data']
    kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
    subdoc = JSON.parse(params['subdoc'])
    kbDoc.setPropVal('ActionabilityDocID.Score.Status',  subdoc['properties']['Status']['value'])
    doc['ActionabilityDocID']['properties']['Score']['properties']['Final Scores'] = subdoc['properties']['Final Scores'] 
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult = apiPut(rsrcPath, JSON.generate(doc), fieldMap)
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
    
  def saveAttendeeInfo()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult = apiGet(rsrcPath, fieldMap)
    doc = apiResult[:respObj]['data']
    kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
    subdoc = JSON.parse(params['subdoc'])
    apiResult = nil
    if(kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores')['Final Scores'].nil?) 
      scoreDoc = kbDoc.getSubDoc('ActionabilityDocID.Score')
      scoreDoc['Score']['properties']['Final Scores'] = { 'properties' => {  'Metadata' => subdoc } }
      apiResult = apiPut(rsrcPath, JSON.generate(kbDoc), fieldMap)
    elsif(kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores.Metadata')['Metadata'].nil?)
      fscoreDoc = kbDoc.getSubDoc('ActionabilityDocID.Score.Final Scores')
      fscoreDoc['Final Scores']['properties']['Metadata'] = subdoc
      apiResult = apiPut(rsrcPath, JSON.generate(kbDoc), fieldMap)
    else
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
      fieldMap[:prop] = "ActionabilityDocID.Score.Final Scores.Metadata"
      apiResult = apiPut(rsrcPath, JSON.generate(subdoc), fieldMap)
    end
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
  def saveUserStatus()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    status = params['status']
    gbLogin = params['gbLogin']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult = apiGet(rsrcPath, fieldMap)
    doc = apiResult[:respObj]['data']
    scorerPresent = false 
    if(doc['ActionabilityDocID']['properties']['Score']['properties']['Scorers'])
      scorers = doc['ActionabilityDocID']['properties']['Score']['properties']['Scorers']['items']
      scorers.each {|scorerObj|
        #$stderr.puts "scorerObj:\n#{scorerObj.inspect}"
        if(scorerObj['Scorer']['value'] == gbLogin)
          scorerPresent = true ;
          break
        end
      }
    end
    if(scorerPresent)
      propPath = "ActionabilityDocID.Score.Scorers.[].Scorer.{\"#{gbLogin}\"}.Status"
      fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
      subdoc = { "value" => status }
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
      apiResult = apiPut(rsrcPath, JSON.generate(subdoc), fieldMap)  
    else
      if(doc['ActionabilityDocID']['properties']['Score']['properties']['Scorers'])
        propPath = "ActionabilityDocID.Score.Scorers.[LAST]"
        fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
        subdoc = { "Scorer" => { "value" => gbLogin, "properties" => { "Status" => { "value" => status }  }  }  } ;
        rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
        apiResult = apiPut(rsrcPath, JSON.generate(subdoc), fieldMap)  
      else
        fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
        subdoc = { "Scorer" => { "value" => gbLogin, "properties" => { "Status" => { "value" => status }  }  }  } ;
        doc['ActionabilityDocID']['properties']['Score']['properties']['Scorers']['items'].push(subdoc)
        apiResult = apiPut(rsrcPath, JSON.generate(doc), fieldMap)  
      end
    end
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
  def saveOverallStatus()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    status = params['status']
    propPath = "ActionabilityDocID.Score.Status"
    fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
    subdoc = { "value" => status }
    apiResult = apiPut(rsrcPath, JSON.generate(subdoc), fieldMap)  
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
end
