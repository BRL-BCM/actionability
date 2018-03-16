

# class with controller methods for the entry page of the actionability
class GenboreeAcEntryController < ApplicationController
  include GenboreeAcDocHelper
  
  unloadable
  
  before_filter :find_project
  before_filter :getKbMount
  before_filter :genboreeAcSettings
  before_filter :find_settings
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
  
  def check_gene
    addProjectIdToParams()
    @projectId = params['id']
    gene = params['gene'].split(",").last
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?matchValue={mv}&matchProp={mp}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = {:grp => gbGroup, :kb=> gbkb, :coll => @acGenesColl, :mp => "Gene", :mv => gene  }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      begin
        if(apiReq.respBody['data'].size > 0)
          apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
        else
          apiReq.sendToClient(404, headers, JSON.generate(apiReq.respBody))
        end
      rescue => err
        apiReq.sendToClient(500, headers, err.message)
      end
    }
    apiReq.get(rsrcPath, fieldMap)
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
        $stderr.debugPuts(__FILE__, __method__, '>>>>>> DEBUG', "versDocs:\n#{JSON.pretty_generate(versDocs)}")
        versDocs.each{|ver| versionHash[ver.keys.first] = ver[ver.keys.first]['data']}
        @docs.each {|doc|
          kbd = BRL::Genboree::KB::KbDoc.new(doc)
          acProps = kbd.getPropProperties("ActionabilityDocID")
          docname = kbd.getPropVal("ActionabilityDocID")
          $stderr.puts "DOCNAME: #{docname.inspect}"
          genes = []
          docsHash = {}
          versDoc = nil
          if (acProps.key?('Genes') and acProps['Genes'].key?('items'))
            kbd.getPropItems("ActionabilityDocID.Genes").each { |geneItem|
              genes << geneItem['Gene']['value']
            }
            #doc['ActionabilityDocID']['properties']['Genes']['items'].each {|geneItem|
            #  genes << geneItem['Gene']['value']
            #}
          end
          
          docsHash['docId'] = kbd.getPropVal("ActionabilityDocID")
          docsHash['disease'] = kbd.getPropVal("ActionabilityDocID.Syndrome")
          docsHash['status'] = kbd.getPropVal("ActionabilityDocID.Status")
          stage1Status = "Incomplete"
          
          if(acProps.key?("Stage 1") and acProps["Stage 1"]['properties'].key?('Final Stage1 Report'))
            stage1Status = kbd.getPropVal("ActionabilityDocID.Stage 1.Final Stage1 Report.Status")
          end
          docsHash['stage1status'] = stage1Status
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
    collName  = @acGenesColl
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
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    collName  = @acCurationColl
    genesColl = @acGenesColl
    acdoc = JSON.parse(params['acdoc'])
    # get the last edited by and on info along with the newly created doc
    getOtherParams = params['getOtherParams'] rescue nil
    # get the genes from the doc to be saved
    genesHash = {}
    apiResult = nil
    acdoc['ActionabilityDocID']['properties']['Genes']['items'].each { |geneItem| genesHash[geneItem['Gene']['value']] = {} }
    # Because the original code "falls through" at the end of its tasks and is not callback based,
    #   we have to do any async stuff needed MUCH later now, up front, because by the time the release code
    #   has does its job (it's not api based, hacked in) it has stopped respecting callbacks.
    # So let's make sure we have the kbdoc with info about template sets since that will be needed (much later)
    #   to render doc-released messages. This makes @templateSetsDoc available, mainly from useful helper methods.
    loadTemplateSetsDoc( env, @project ) { |result|
      if( result.is_a?(Hash) and !result.key?(:err) and result[:obj].is_a?(BRL::Genboree::KB::KbDoc) )
        # Let's also get model. Having @model is useful and necessary MUCH later, but as above we need to get these things
        #   before the code stops being callback based and just does direct sendToClient() from almost every method.
        getModelAsync(collName) { |model|
          if( model.is_a?(Hash) )
            @model = model
            unless (genesHash.empty?)
              rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true&matchProp=Gene&matchValues={geneNames}"
              fieldMap  = {:grp => gbGroup, :kb => gbkb, :coll => genesColl, :geneNames => genesHash.keys}
              #apiResult = apiGet(rsrcPath, fieldMap)
              #genesObj = apiResult[:respObj]['data']
              apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
              apiReq.bodyFinish {
                headers = apiReq.respHeaders
                status = apiReq.respStatus
                headers['Content-Type'] = "text/plain"
                begin
                  genesObj = apiReq.respBody['data']
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
                  saveNewAcDoc(acdoc)
                rescue => err
                  $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{err.message}\n\nTRACE:\n#{err.backtrace.join("\n")}")
                  apiReq.sendToClient(500, headers, err.message)
                end
              }
              apiReq.get(rsrcPath, fieldMap)
            else
              saveNewAcDoc(acdoc)
            end
          else
            msg = ( @lastApiReqErrText or "ERROR: could not get model for #{collName.inspect} but getModelAsync() couldn't save info about why we couldn't." )
            err = ( @lastApiReqErr or ArgumentError.new( msg ) )
            headers = @lastApiReq.respHeaders rescue []
            status = @lastApiReq.respStatus rescue 500
            headers['Content-Type'] = 'application/json'
            resp = { "status" => { "statusCode" => status, "msg" => err.message } }
            $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Get model failed and info logged. Returning error payload:\n\t#{resp.to_json}")
            @lastApiReq.sendToClient(status, headers, resp.to_json)
          end
        }
      else # getting template sets info KbDoc failed?
        err = ( result[:err].message or IOError.new( "ERROR: could not retrieve the KbDoc with info about the various TemplateSets that are available." ) )
        headers = @lastApiReq.respHeaders rescue []
        status = @lastApiReq.respStatus rescue 500
        headers['Content-Type'] = 'application/json'
        resp = { "status" => { "statusCode" => status, "msg" => err.message } }
        $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Get template sets info KbDoc failed and info logged. Returning error payload:\n\t#{resp.to_json}")
        @lastApiReq.sendToClient(status, headers, resp.to_json)
      end
    }
  end
  
  # get a set of action documents matching a syndrome
  def actionDocs()
    addProjectIdToParams()
    @projectId = params['id']
    $stderr.puts "params (actionDocs): #{params.inspect}"
    apiResult = nil
    collName  = @acCurationColl
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
  
  # Helpers
  
  def saveNewAcDoc(acDoc)
    # get the last edited by and on info along with the newly created doc
    getOtherParams = params['getOtherParams'] rescue nil
    kbAcDoc = BRL::Genboree::KB::KbDoc.new(acDoc)
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      if(status >= 200 and status < 400)
        $stderr.debugPuts(__FILE__, __method__, '>>>>>> DEBUG', "New Ac doc created.")
        resp = apiReq.respBody
        docname = resp['data']['ActionabilityDocID']['value']
        # Before responding to client, save the same doc in the release KB with the 'In Preparation' status
        kbAcDoc.setPropVal("ActionabilityDocID.Status", "In Preparation")
        kbAcDoc.setPropVal("ActionabilityDocID", docname)
        if(getOtherParams)
          begin
            # get the edited by
            rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{docname}/ver/HEAD?detailed=true"
            fieldMap = {:grp => gbGroup, :kb => gbkb, :coll => @acCurationColl, :docname => docname}
            apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
            apiReq2.bodyFinish {
              headers = apiReq2.respHeaders
              status = apiReq2.respStatus
              headers['Content-Type'] = "text/plain"
              begin
                versDoc = apiReq2.respBody['data']
                $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "versDoc:\n#{JSON.pretty_generate(versDoc)}")
                if (versDoc)
                  editedby = nil
                  gblogin = versDoc['versionNum']['properties']['author']['value']
                  loginInfo = getGbAccount(gblogin)
                  if(loginInfo)
                    editedby = "#{loginInfo['firstName']} #{loginInfo['lastName']}"
                  else
                    editedby = versDoc['versionNum']['properties']['author']['value']
                  end
                  resp['data']['editedBy'] = editedby
                  resp['data']['editedon'] = versDoc['versionNum']['properties']['timestamp']['value'].split(/\s*-/).first
                else
                  resp['data']['editedBy'] = nil
                  resp['data']['editedon'] = nil
                end
                initUploadReleaseDoc(kbAcDoc, false, resp)  
              rescue => err
                $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{err.message}\n\nTRACE:\n#{err.backtrace.join("\n")}")
                apiReq2.sendToClient(500, headers, err.message)  
              end
            }
            apiReq2.get(rsrcPath, fieldMap)
          rescue => err
            $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{err.message}\n\nTRACE:\n#{err.backtrace.join("\n")}")
            apiReq.sendToClient(500, headers, err.message)
          end
        else
          initUploadReleaseDoc(kbAcDoc, false, resp)
        end
      else
        apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
      end
    }
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    fieldMap  = {:grp => gbGroup, :kb => gbkb, :coll => @acCurationColl, :doc => ""}
    apiReq.put(rsrcPath, fieldMap, JSON.generate(acDoc))
  end
  
end
