require 'yaml'
require 'json'
require 'uri'
require 'brl/rest/apiCaller'
require 'brl/util/util'
include BRL::REST

# class with controller methods for the entry page of the actionability
class GenboreeAcEntryController < ApplicationController
  include GenboreeAcHelper
  
  unloadable
  
  before_filter :find_project
  before_filter :getKbMount
  respond_to :json
  
  # Shows all the documents in the actionability collection
  # Uses skip and limit to get the paging
  # In addition, uses matchOrderBy to sort wrp to prop(s)
  # matchProp and matchValues are used to make the skip and limit working
  # final response must contain the total number of records in the collection
  def show()
    addProjectIdToParams()
    @projectId = params['id']
    # Final response
    @resp = {}
    @resp['totalCount'] = nil
    @resp['data'] = []
    
    # params
    @collName  = params['acCurationColl']
    @matchOrderBy = params['matchOrderBy'].split(",")
    @matchOrderBy = @matchOrderBy.empty? ? ["ActionabilityDocID.Syndrome", "ActionabilityDocID.Genes.Gene"] : @matchOrderBy
    @matchProps = []
    @matchProps = params['matchProps'].split(",")
    @matchMode = params['matchMode']
    @matchValue = params['matchValue']

    totalCount = params['totalCount'] rescue nil
    targetHost = getHost()

    # instantiate the async requester class
    @apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    
    # no total count - then get that first before getting the data for the entry page
    if(totalCount.nil? or totalCount.empty?)
      getTotalCount()
    else
      # get the data for the entry page
      @resp['totalCount'] = totalCount
      getEntryData()
    end

  end

  def getTotalCount()
    gbGroup = getGroup()
    gbkb = getKb()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=false&matchProps={matchProps}&matchValue={matchValue}&matchMode={matchMode}"
    fieldMap  = {:grp => gbGroup, :kb=> gbkb, :coll => @collName, :matchProps => @matchProps, :matchValue => @matchValue, :matchMode => @matchMode}
    @apiReq.bodyFinish {
      headers = @apiReq.respHeaders
      status = @apiReq.respStatus
      if(@apiReq.apiDataObj)
        @resp['totalCount'] = @apiReq.apiDataObj.size
        getEntryData()
      else 
        # no data obj - send the failed response
        headers['Content-Type'] = "text/plain"
        @apiReq.sendToClient(status, headers, JSON.generate(@apiReq.respBody))
      end
    }
    @apiReq.get(rsrcPath, fieldMap)
  end

  def getEntryData()
    skip = params['start']
    limit = params['limit']
    @docs = []
    gbGroup = getGroup()
    gbkb = getKb()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true&matchProps={matchProps}&matchValue={matchValue}&matchMode={matchMode}&matchOrderBy={matchOrderBy}&skip={skip}&limit={limit}"
    fieldMap  = {:grp => gbGroup, :kb=> gbkb, :coll => @collName ,:matchProps => @matchProps, :matchValue => @matchValue, :matchMode => @matchMode, :matchOrderBy => @matchOrderBy, :skip => skip, :limit => limit}
    @apiReq.bodyFinish {
      headers = @apiReq.respHeaders
      status = @apiReq.respStatus
      if(@apiReq.apiDataObj and !@apiReq.apiDataObj.empty?)
        @docs = @apiReq.apiDataObj
        docIDs = []
        @docs.each{|document| docIDs << document['ActionabilityDocID']['value'] }
        getVersionDocs(docIDs)
      else
        headers['Content-Type'] = "text/plain"
        @apiReq.sendToClient(status, headers, JSON.generate(@apiReq.respBody))
      end
    }
    @apiReq.get(rsrcPath, fieldMap)
  end

  def getVersionDocs(docIDs)
    versionHash = {}
    gbGroup = getGroup()
    gbkb = getKb()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs/ver/HEAD?docIDs={docIDs}&authorFullName=firstlast"
    fieldMap = {:grp => gbGroup, :kb=> gbkb, :coll => @collName, :docIDs => docIDs}
    @apiReq.bodyFinish {
      headers = @apiReq.respHeaders
      status = @apiReq.respStatus
      versDocs = @apiReq.apiDataObj
      if(versDocs)
        versDocs.each{|ver| versionHash[ver.keys.first] = ver[ver.keys.first]['data']}
        @docs.each {|doc|
          docname = doc['ActionabilityDocID']['value']
          $stderr.puts "DOCNAME: #{docname.inspect}"
          genes = []
          docsHash = {}
          versDoc = nil
          if (doc['ActionabilityDocID']['properties'].key?('Genes') and doc['ActionabilityDocID']['properties']['Genes'].key?('items'))
             doc['ActionabilityDocID']['properties']['Genes']['items'].each {|geneItem|
               genes << geneItem['Gene']['value']
             }
          end
          docsHash['docId'] = doc['ActionabilityDocID']['value']
          docsHash['disease'] = doc['ActionabilityDocID']['properties']['Syndrome']['value']
          docsHash['status'] = doc['ActionabilityDocID']['properties']['Status']['value']
          docsHash['genes'] = genes.sort.join(", ")
          
          #Get the author and timestamp for each of the doc
          if (versionHash.key?(docname))
            if(versionHash[docname]['versionNum']['properties'].key?('authorFullName'))
              docsHash['editedby'] = versionHash[docname]['versionNum']['properties']['authorFullName']['value']
            else
              docsHash['editedby'] = versionHash[docname]['versionNum']['properties']['author']['value']
            end
            docsHash['editedon'] = versionHash[docname]['versionNum']['properties']['timestamp']['value'].split(/\s*-/).first
          else
            docsHash['editedby'] = nil
            docsHash['editedon'] = nil
          end
          @resp['data'] << docsHash
        }
        headers['Content-Type'] = "text/plain"
        @apiReq.sendToClient(status, headers, JSON.generate(@resp))
      else
        headers['Content-Type'] = "text/plain"
        @apiReq.sendToClient(status, headers, JSON.generate(@apiReq.respBody))
      end

    }
    $stderr.debugPuts(__FILE__, __method__, '>>>>>> DEBUG', "REQID=====[#{@apiReq.railsRequestId.inspect}] ......")
    @apiReq.get(rsrcPath, fieldMap)

  end



  # gets all the genes doc identifiers
  def genes()
    addProjectIdToParams()
    @projectId = params['id']
    #$stderr.puts "params (genes): #{params.inspect}"
    apiResult = nil
    collName  = params['acGenesColl']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs"

    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = {:grp => gbGroup, :kb=> gbkb, :coll => collName }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
    }
   apiReq.get(rsrcPath, fieldMap)
  end
  
  
  # save actionability document and return the saved document identifier 
  def save()
    addProjectIdToParams()
    @projectId = params['id']
    #$stderr.puts "params (SAVE ACTIONDOC): Saving . . #{params.inspect}"
    docId = ""
    collName  = params['acCurationColl']
    genesColl = params['acGenesColl']
    acdoc = JSON(params['acdoc'])
    # get the last edited by and on info along with the newly created doc
    getOtherParams = params['getOtherParams'] rescue nil
    # get the genes from the doc to be saved
    genesHash = {}
    apiResult = nil
    acdoc['ActionabilityDocID']['properties']['Genes']['items'].each { |geneItem| genesHash[geneItem['Gene']['value']] = {} }
    unless (genesHash.empty?)
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true&matchProp=Gene&matchValues={geneNames}"
      fieldMap  = {:coll => genesColl, :geneNames => genesHash.keys}
      apiResult = apiGet(rsrcPath, fieldMap)
      genesObj = apiResult[:respObj]['data']
      # get the HGNCId for the genes
      unless(genesObj.empty?)
        genesObj.each {|gg|
          genesHash[gg['Gene']['value']]['HGNCId'] = gg['Gene']['properties']['HGNCId']['value']
          genesHash[gg['Gene']['value']]['GeneOMIM'] = gg['Gene']['properties']['GeneOMIM']['value']
        }
        acdoc['ActionabilityDocID']['properties']['Genes']['items'].each { |geneItem|
          geneItem['Gene']['properties']['HGNCId']['value'] = genesHash[geneItem['Gene']['value']]['HGNCId']
          geneItem['Gene']['properties']['GeneOMIM']['value'] = genesHash[geneItem['Gene']['value']]['GeneOMIM']
        }
      end
    end
    
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = {:coll => collName, :doc => docId}
    apiResult = apiPut(rsrcPath, JSON.generate(acdoc), fieldMap)
    # fetch last edited on and by info before rendering the response
    resp = Marshal.load(Marshal.dump(apiResult))
    if(apiResult[:respObj]['data'] and getOtherParams)
      # get the edited by
      docname = apiResult[:respObj]['data']['ActionabilityDocID']['value']
      apiResult = nil
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{docname}/ver/HEAD"
      fieldMap = {:coll => collName, :docname => docname}
      apiResult  = apiGet(rsrcPath, fieldMap)
      versDoc = apiResult[:respObj]['data']
      if (versDoc)
        editedby = nil
        gblogin = versDoc['versionNum']['properties']['author']['value']
        loginInfo = getGbAccount(gblogin)
        if(loginInfo)
          editedby = "#{loginInfo['firstName']} #{loginInfo['lastName']}"
        else
          editedby = versDoc['versionNum']['properties']['author']['value']
        end
        resp[:respObj]['data']['editedBy'] = editedby
        resp[:respObj]['data']['editedon'] = versDoc['versionNum']['properties']['timestamp']['value'].split(/\s*-/).first
      else
        resp[:respObj]['data']['editedBy'] = nil
        resp[:respObj]['data']['editedon'] = nil
      end
    end
    respond_with(resp[:respObj], :status => resp[:status], :location => "")
  end
  
  # get a set of action documents matching a syndrome
  def actionDocs()
    addProjectIdToParams()
    @projectId = params['id']
    $stderr.puts "params (actionDocs): #{params.inspect}"
    apiResult = nil
    collName  = params['acCurationColl']
    matchProp = params['matchProp']
    matchValues = params['matchValues']
    matchMode = params['matchMode']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true&matchProp={matchProp}&matchValues={matchValues}&matchMode={matchMode}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = {:grp => gbGroup, :kb=> gbkb, :coll => collName, :matchProp => matchProp, :matchValues => matchValues, :matchMode => matchMode}
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
    }
   apiReq.get(rsrcPath, fieldMap) 
  end
  
end
