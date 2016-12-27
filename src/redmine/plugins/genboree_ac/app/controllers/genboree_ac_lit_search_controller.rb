require 'yaml'
require 'json'
require 'uri'
require 'brl/util/util'
require 'brl/genboree/kb/kbDoc'

class GenboreeAcLitSearchController < ApplicationController
  include GenboreeAcHelper

  respond_to :json
  before_filter :find_project
  unloadable

  def saveSourceInfo()
    addProjectIdToParams()
    @projectId = params['id']
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    searchSource    = params['searchSource']
    subdoc = JSON.parse(params['subdoc'])
    searchString = params['searchString']
    # First check if Literature Search exists in the document
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = { :coll => collName, :doc => docId } 
    apiResult  = apiGet(rsrcPath, fieldMap)
    doc = apiResult[:respObj]['data']
    kbDoc = BRL::Genboree::KB::KbDoc.new(doc)
    litSearchDoc = kbDoc.getSubDoc('ActionabilityDocID.LiteratureSearch')['LiteratureSearch']
    if(litSearchDoc.nil? or kbDoc.getSubDoc('ActionabilityDocID.LiteratureSearch.Sources')['Sources'].nil? or kbDoc.getPropItems('ActionabilityDocID.LiteratureSearch.Sources').nil?) # LiteratureSearch does not exist yet in the document. Insert it and do a PUT
      status = "Incomplete"
      if(!litSearchDoc.nil? and kbDoc.getPropVal('ActionabilityDocID.LiteratureSearch.Status'))
        status = kbDoc.getPropVal('ActionabilityDocID.LiteratureSearch.Status')
      end
      newSubDoc = { "LiteratureSearch" => { "properties" => { "Status" => { "value" => status }, "Sources" => { "value" => 1, "items" => [ { "Source" => { "value" => searchSource, "properties" => { "Notes" => { "value" => ""}, "SearchStrings" => { "value" => 1, "items" => [ subdoc ] }} }} ] } } } }
      doc['ActionabilityDocID']['properties']['LiteratureSearch'] = newSubDoc['LiteratureSearch']
      apiResult = apiPut(rsrcPath, JSON.generate(doc), fieldMap)
    else # LiteratureSearch exists. Check if the Source exists
      sources = kbDoc.getPropItems('ActionabilityDocID.LiteratureSearch.Sources')
      sourceFound = false
      sourceItemsFound = false
      sourceKbDoc = nil
      #$stderr.puts "sources:\n\n #{sources.inspect}"
      sources.each { |sourceObj|
        if(sourceObj['Source']['value'] == searchSource)
          sourceKbDoc = BRL::Genboree::KB::KbDoc.new(sourceObj)
          $stderr.puts "sourceKbDoc:\n\n#{JSON.pretty_generate(sourceKbDoc)}\n\nsourceKbDoc.getPropItems('Source.SearchStrings'):\n#{sourceKbDoc.getPropItems('Source.SearchStrings')}"
          if(!sourceKbDoc.getPropItems('Source.SearchStrings').nil?)
            sourceFound = true
          end
          if(sourceKbDoc.getPropItems('Source.SearchStrings').size > 0)
            sourceItemsFound = true 
          end
        end
      }
      $stderr.puts "sourceFound: #{sourceFound.inspect}"
      if (!sourceFound and !sourceItemsFound) 
        newSubDoc =  { "Source" => { "value" => searchSource, "properties" => { "Notes" => { "value" => ""}, "SearchStrings" => { "value" => 1, "items" => [ subdoc ] }} }} 
        sources.push(newSubDoc)
        kbDoc.setPropItems('ActionabilityDocID.LiteratureSearch.Sources', sources)
        apiResult = apiPut(rsrcPath, JSON.generate(kbDoc), fieldMap)
      elsif(sourceFound and !sourceItemsFound)
        sourceKbDoc.setPropItems('Source.SearchStrings', [subdoc])
        apiResult = apiPut(rsrcPath, JSON.generate(kbDoc), fieldMap)
      end
    end
    # Do another PUT for just the searchString: this is required for proper history tracking of the SearchString item because if ONLY the previous PUT happened, it will not track the revision of the SearchString item doc.
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    searchString.gsub!(/\"/, "\\\"")
    searchString.gsub!(/,/, "\\,")
    fieldMap  = { :coll => collName, :doc => docId, :prop => "ActionabilityDocID.LiteratureSearch.Sources.[].Source.{\"#{searchSource}\"}.SearchStrings.[].SearchString.{\"#{searchString}\"}" }
    apiResult = apiPut(rsrcPath, JSON.generate(subdoc['SearchString']), fieldMap)
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end

  def saveStatus()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    status    = params['value']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    fieldMap  = { :coll => collName, :doc => docId, :prop => "ActionabilityDocID.LiteratureSearch.Status" }
    apiResult = apiPut(rsrcPath, JSON.generate({ "value" => status }), fieldMap)
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
  def remove()
    addProjectIdToParams()
    @projectId = params['id']
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    searchSource    = params['searchSource']
    searchString = params['searchString']
    origSearchStr = params['origSearchStr']
    addNew = params['addNew']
    if(origSearchStr == "" and addNew == "false")
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
      fieldMap = { :coll => collName, :doc => docId }
      apiResult = apiGet(rsrcPath, fieldMap)
      doc = apiResult[:respObj]['data']
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
      apiResult = apiPut(rsrcPath, JSON.generate(kbDoc), fieldMap)
    else
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
      searchString.gsub!(/\"/, "\\\"")
      searchString.gsub!(/,/, "\\,")
      fieldMap  = { :coll => collName, :doc => docId, :prop => "ActionabilityDocID.LiteratureSearch.Sources.[].Source.{\"#{searchSource}\"}.SearchStrings.[].SearchString.{\"#{searchString}\"}" }
      apiResult = apiDelete(rsrcPath, fieldMap)
    end
    
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end

end
