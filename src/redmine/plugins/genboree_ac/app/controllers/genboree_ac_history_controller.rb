require 'yaml'
require 'json'
require 'uri'
require 'differ'
require 'brl/util/util'
require 'brl/genboree/kb/kbDoc'


class GenboreeAcHistoryController < ApplicationController
  include GenboreeAcHelper

  unloadable

  SEARCH_LIMIT = 20
  before_filter :find_project
  
  respond_to :json

  def show()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    propPath = params['propPath']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}/revs"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
    apiResult  = apiGet(rsrcPath, fieldMap)
    jsonResp = JSON.generate(apiResult[:respObj])
    render(:json => jsonResp, :content_type => "text/html", :status => apiResult[:status])
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
    latestInterventionsStr = constructInterventionList(rev2Interventions[latestRev])
    olderInterventionsStr = constructInterventionList(rev2Interventions[olderRev])
    diffByWord = Differ.diff_by_word(latestInterventionsStr, olderInterventionsStr)  # Latest version first
    diffedHtml = diffByWord.format_as(:html)
    respJson = { "data" => diffedHtml }
    render(:json => JSON.generate(respJson), :content_type => "text/html", :status => 200)
  end
  
  def diffBaseSection()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    propPath = params['propPath']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}/revs"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    rev2Content = JSON.parse(params['rev2Content']) ;
    olderRev, latestRev = returnNewerAndOlderRevisions(rev2Content)
    latestPropVals = rev2Content[latestRev]
    olderPropVals = rev2Content[olderRev]
    respHash = constructRespHash(latestPropVals, olderPropVals)
    $stderr.puts "respHash:\n#{respHash.inspect}"
    respHash.each_key { |prop|
      latestPropVal = ""
      olderPropVal = ""
      addField = false
      if( prop =~ /^AdditionalFields/ )
        addField = true
        prop = prop.gsub(/^AdditionalFields-/, "")
        latestPropVal = rev2Content[latestRev]['Additional Fields'][prop]
        olderPropVal = rev2Content[olderRev]['Additional Fields'][prop]
      else
        latestPropVal = rev2Content[latestRev][prop]
        olderPropVal = rev2Content[olderRev][prop]
      end
      diffStr = generateDiffForPropVals(prop, latestPropVal, olderPropVal)
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
  
  def revertOutcome()
    addProjectIdToParams()
    @projectId = params['id']
    outcome = params['outcome']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    collName  = params['acCurationColl']
    docId = params['docIdentifier']
    subdoc = params['subdoc']
    propPath = "ActionabilityDocID.Stage 2.Outcomes.[].Outcome.{\"#{outcome}\"}"
    fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
    apiResult = apiPut(rsrcPath, subdoc, fieldMap)
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
  def revertStage2BaseSection()
    addProjectIdToParams()
    @projectId = params['id']
    outcome = params['outcome']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    collName  = params['acCurationColl']
    docId = params['docIdentifier']
    subdoc = params['subdoc']
    propPath = params['propPath']
    fieldMap  = { :coll => collName, :doc => docId, :prop => propPath } 
    apiResult = apiPut(rsrcPath, subdoc, fieldMap)
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
  # Helper methods
  def cleanRespHash(respHash)
    respHash.each_key { |key|
      respHash.delete(key) if(key =~ /^AdditionalFields-/)  
    }
  end
  
  def generateDiffForPropVals(prop, latestPropVal, olderPropVal)
    latestStr = ""
    olderStr = ""
    if(prop == 'Outcomes' or prop == 'References')
      latestStr = latestPropVal.join(", ")
      olderStr = olderPropVal.join(", ")
    else
      latestStr = latestPropVal
      olderStr = olderPropVal
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
    retVal = ""
    list = []
    interventions.each {|interventionObj|
      list.push(interventionObj['Intervention']['value'])
    }
    if(!list.empty?)
      retVal = list.join("</br>")
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
