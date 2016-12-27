class GenboreeAcDocController < ApplicationController
  include GenboreeAcDocHelper

  unloadable

  SEARCH_LIMIT = 20
  before_filter :find_project, :genboreeAcSettings
  
  respond_to :json

  def show()
    rsrcPath = ""
    propPath = params['propPath']
    if( propPath == '/' ) # Get the whole doc
      rsrcPath  = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    else # get the subdoc
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    end
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => propPath } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  
  def model()
    collName  = params['coll']
    getModelAsync(collName){
      headers = @lastApiReq.respHeaders
      status = @lastApiReq.respStatus
      headers['Content-Type'] = "text/plain"
      @lastApiReq.sendToClient(status, headers, JSON.generate(@lastApiReq.respBody))
    }
  end
  

  
  def downloadRefFile()
    docId     = params['docId']
    refValue  = params['refValue']
    mimeType = params['mimeType']
    getDocAsync(docId, @acCurationColl){
      begin
        resp = nil
        $stderr.puts "Got Doc for download"
        kbd = BRL::Genboree::KB::KbDoc.new(@lastApiReq.respBody['data'])
        refItems = kbd.getPropItems( "ActionabilityDocID.RefMetadata")
        refFileUrl = nil
        refItems.each { |refItem|
          refKbd =  BRL::Genboree::KB::KbDoc.new(refItem)
          if(refKbd.getPropVal('Reference') == "/coll/#{CGI.escape(@acRefColl)}/doc/#{CGI.escape(refValue)}")
            refFileUrl = refKbd.getPropVal('Reference.RefExcerptFile')
            break
          end
        }
        targetHost = getHost()
        rsrcPath = URI.parse(refFileUrl).path.chomp("?")
        rsrcPath << "/data"
        downloader = GbApi::FileDownloadAsyncApiRequester.new(env, targetHost, @project)
        downloader.mimeType = mimeType
        downloader.get(rsrcPath, {})
      rescue => err
        headers = @lastApiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        @lastApiReq.sendToClient(status, headers, JSON.generate({"status" => { "msg" => err, "statusCode" => 500}}))
      end
    }
  end
  
  def refFiles()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      kbCollDoc = BRL::Genboree::KB::KbDoc.new(apiReq.respBody['data'])
      kbDb = kbCollDoc.getPropVal('name.kbDbName')
      if(kbDb.nil? or kbDb.empty?)
        apiReq.sendToClient(404, headers, JSON.generate({"status" => { "msg" => "This KB does not have a database associated with it. Please contact a project manager to resolve this issue.", "statusCode" => 404}}))  
      else
        rsrcPath = "/REST/v1/grp/{grp}/db/{db}/files?detailed=false"
        targetHost = getHost()
        gbGroup = getGroup()
        gbkb = getKb()
        fieldMap  = { :grp => gbGroup, :db => kbDb } 
        apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
        apiReq2.bodyFinish {
          headers = apiReq.respHeaders
          status = apiReq.respStatus
          headers['Content-Type'] = "text/plain"
          apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
        }
        apiReq2.get(rsrcPath, fieldMap)
      end
    }
    apiReq.get(rsrcPath, fieldMap)
    
  end
  
  def refFileDelete()
    docId     = params['docId']
    refValue  = params['refValue']
    getDocAsync(docId, @acCurationColl){
      begin
        kbd = BRL::Genboree::KB::KbDoc.new(@lastApiReq.respBody['data'])
        refItems = kbd.getPropItems( "ActionabilityDocID.RefMetadata")
        newRefItems = []
        refFileUrl = nil
        refItems.each { |refItem|
          refKbd =  BRL::Genboree::KB::KbDoc.new(refItem)
          if(refKbd.getPropVal('Reference') != "/coll/#{CGI.escape(@acRefColl)}/doc/#{CGI.escape(refValue)}")
            newRefItems << refItem
          end
        }
        kbd.setPropItems("ActionabilityDocID.RefMetadata", newRefItems)
        rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
        fieldMap = { :coll => @acCurationColl, :doc => docId }
        apiResult = apiPut(rsrcPath, JSON.generate(kbd), fieldMap)
        headers = @lastApiReq.respHeaders
        status = 200
        headers['Content-Type'] = "text/plain"
        if(apiResult[:status] != 200)
          status =  apiResult[:status]              
        else
          apiResult[:respObj]["success"] = true 
        end
        @lastApiReq.sendToClient(status, headers, JSON.generate(apiResult[:respObj]))
      rescue => err
        headers = @lastApiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        @lastApiReq.sendToClient(status, headers, JSON.generate({"status" => { "msg" => err, "statusCode" => 500}}))
      end
    }
  end
  
  def fileMimeType()
    @gbHost = getHost()
    @gbGroup = getGroup()
    @gbKb = getKb()
    fileName = params['fileName']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}"
    apiReq = GbApi::JsonAsyncApiRequester.new(env, @gbHost, @project)
    @apiBody = ""
    @apiStatus = nil
    @apiHeaders = nil
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        kbCollDoc = BRL::Genboree::KB::KbDoc.new(apiReq.respBody['data'])
        kbDb = kbCollDoc.getPropVal('name.kbDbName')
        if(kbDb.nil? or kbDb.empty?)
          apiReq.sendToClient(404, headers, JSON.generate({"status" => { "msg" => "This KB does not have a database associated with it. Please contact a project manager to resolve this issue.", "statusCode" => 404}}))  
        else
          @kbDb = kbDb
          rsrcPath = "/REST/v1/grp/{grp}/db/{db}/file/{file}/mimeType"
          apiReq2 = GbApi::JsonAsyncApiRequester.new(env, @gbHost, @project)
          @apiBody = ""
          @apiStatus = nil
          @apiHeaders = nil
          @mimeType = "application/octet-stream"
          apiReq2.bodyFinish {
            headers = apiReq.respHeaders
            status = apiReq.respStatus
            apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
          }
          apiReq2.get(rsrcPath, { :grp => @gbGroup, :db => @kbDb, :file => fileName })
        end
      rescue => err
        apiReq.sendToClient(500, apiReq.respHeaders, JSON.generate({"status" => { "msg" => err, "statusCode" => 500}}))  
      end
    }
    apiReq.get(rsrcPath, { :grp => @gbGroup, :kb => @gbKb })
  end
  
  def refFileUpload()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    acCollName  = params['acCurationColl']
    refCollName = params['acRefColl']
    docId     = params['docIdentifier']
    refValue = params['refValue']
    fieldMap  = { :grp => gbGroup, :kb => gbkb } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        kbCollDoc = BRL::Genboree::KB::KbDoc.new(apiReq.respBody['data'])
        kbDb = kbCollDoc.getPropVal('name.kbDbName')
        if(kbDb.nil? or kbDb.empty?)
          apiReq.sendToClient(404, headers, JSON.generate({"status" => { "msg" => "This KB does not have a database associated with it. Please contact a project manager to resolve this issue.", "statusCode" => 404}}))  
        else
          rackFileObj = params['fileName']
          fileName = rackFileObj.original_filename
          uploadFilePath = rackFileObj.tempfile.path
          fileNameToUse = "Actionability%20Reference%20Files/Excerpt%20Files/#{CGI.escape(docId)}/#{CGI.escape(refValue)}/#{CGI.escape(File.basename(fileName))}"
          fieldMap  = { :grp => gbGroup, :db => kbDb }
          rsrcPath = "/REST/v1/grp/{grp}/db/{db}/file/#{fileNameToUse}/data"
          apiResult = apiPut(rsrcPath, File.open(uploadFilePath), fieldMap)
          respObj = apiResult[:respObj]
          # Update the actionability doc with the ref file if everything went fine
          if(apiResult[:status] == 200)
            rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?"
            fieldMap = { :grp => gbGroup, :kb => gbkb, :coll => acCollName, :doc => docId }
            apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
            apiReq2.bodyFinish {
              begin
                kbd = BRL::Genboree::KB::KbDoc.new(apiReq2.respBody['data'])
                excerptFileUrl = "http://#{targetHost}/REST/v1/grp/#{CGI.escape(gbGroup)}/db/#{CGI.escape(kbDb)}/file/#{fileNameToUse}"
                refUrlValue = "/coll/#{CGI.escape(refCollName)}/doc/#{CGI.escape(refValue)}"
                newRefItem = {
                  "Reference" => {
                    "value" => refUrlValue,
                    "properties" => {
                      "RefExcerptFile" => {
                        "value" => excerptFileUrl
                      }
                    }
                  }    
                }
                if(kbd.getSubDoc("ActionabilityDocID.RefMetadata")["RefMetadata"].nil?)
                  kbd['ActionabilityDocID']['properties']['RefMetadata'] = { "items" => [ newRefItem ] }
                else
                  references = kbd.getPropItems('ActionabilityDocID.RefMetadata')
                  refFound = false
                  references.each {|refObj|
                    if(refObj['Reference']['value'] == refUrlValue)
                      kbRefDoc = BRL::Genboree::KB::KbDoc.new(refObj)
                      kbRefDoc.setPropVal('Reference.RefExcerptFile', excerptFileUrl)
                      refFound = true
                      break
                    end
                  }
                  unless(refFound)
                    kbd.addPropItem('ActionabilityDocID.RefMetadata', newRefItem)
                  end
                end
                rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
                fieldMap  = { :coll => acCollName, :doc => docId }
                apiResult = apiPut(rsrcPath, JSON.generate(kbd), fieldMap)
                headers = apiReq2.respHeaders
                status = 200
                headers['Content-Type'] = "text/plain"
                if(apiResult[:status] != 200)
                  status =  apiResult[:status]              
                else
                  apiResult[:respObj]["success"] = true 
                end
                `rm -f #{uploadFilePath}`
                apiReq2.sendToClient(status, headers, JSON.generate(apiResult[:respObj]))
              rescue => err
                headers = apiReq2.respHeaders
                status = 500
                headers['Content-Type'] = "text/plain"
                apiReq2.sendToClient(status, headers, JSON.generate({"status" => { "msg" => err, "statusCode" => 500}}))
              end
            }
            apiReq2.get(rsrcPath, fieldMap)
          else
            #respond_with(respObj, :status => apiResult[:status], :location => "")
            apiReq.sendToClient(apiResult[:status], headers, JSON.generate(respObj))
          end
        end
      rescue => err
        headers = apiReq.respHeaders
        headers['Content-Type'] = "text/plain"
        $stderr.debugPuts(__FILE__, __method__, "ERROR", "#{err}\n\nBacktrace:\n#{err.backtrace.join("\n")}")
        apiReq.sendToClient(500, headers, JSON.generate({"status" => { "msg" => err, "statusCode" => 500}}))
      end
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  
  def syndrome()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    getDocAsync(docId, collName){
      begin
        resp = nil
        if(@lastApiReq.respBody['data'])
          kbd = BRL::Genboree::KB::KbDoc.new(@lastApiReq.respBody['data'])
          syndromeDoc = kbd.getSubDoc( "ActionabilityDocID.Syndrome")['Syndrome']
          resp = constructSyndromeRespObj(syndromeDoc)
        else
          resp = @lastApiReq.respBody
        end
        headers = @lastApiReq.respHeaders
        status = @lastApiReq.respStatus
        headers['Content-Type'] = "text/plain"
        @lastApiReq.sendToClient(status, headers, JSON.generate(resp))
      rescue => err
        headers = @lastApiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        @lastApiReq.sendToClient(status, headers, JSON.generate({"status" => { "msg" => err, "statusCode" => 500}}))
      end
    }
  end
  
  def saveSyndromeInfo()
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    subdoc    = params['subdoc']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    fieldMap  = { :coll => collName, :doc => docId, :prop => "ActionabilityDocID.Syndrome" } 
    apiResult = apiPut(rsrcPath, subdoc, fieldMap)
    respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
  end
  
  def saveStatusInfo()
    rsrcPath = ""
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    status    = params['status']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    fieldMap  = { :coll => collName, :doc => docId, :prop => "ActionabilityDocID.Status" } 
    apiResult = apiPut(rsrcPath, JSON.generate({ 'value' => status }), fieldMap)
    if( apiResult[:respObj]['status']['statusCode'] == "OK" )
      # If the status has been updated to 'Released', we need to upload this document to the 'Release' KB as well.
      if( status == 'Released' )
        getDocAsync( docId, collName ) { |kbDoc|
          initUploadReleaseDoc( kbDoc )
        }
      else
        respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
      end
    else
      respond_with(apiResult[:respObj], :status => apiResult[:status], :location => "")
    end
  end
  
  def saveGenesInfo()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true&matchValues={mv}"
    collName  = params['acCurationColl']
    genes     = JSON.parse(params['geneList'])
    docId     = params['docIdentifier']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    geneLookup = {}
    genes.each { |gene|
      geneLookup[gene] = false
    }
    $stderr.debugPuts(__FILE__, __method__, "DEBUG", "genes: #{genes.inspect}")
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => @acGenesColl, :mv => genes } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        geneList = apiReq.respBody['data']
        $stderr.debugPuts(__FILE__, __method__, "DEBUG", "geneList: #{geneList.inspect}")
        # Check if all the entered genes are in the response. If not, respond with an error
        geneObjList = []
        geneList.each { |geneObj|
          geneDoc = BRL::Genboree::KB::KbDoc.new(geneObj)
          gene = geneDoc.getPropVal('Gene')
          geneLookup[gene] = true
          geneDoc.setPropVal("Gene.GeneFunction", geneDoc.getPropVal("Gene.Name").deep_clone)
          geneDoc.delProp("Gene.Name")
          geneObjList << geneDoc
        }
        missingGenes = []
        geneLookup.each_key { |gene|
          missingGenes << gene if(!geneLookup[gene])
        }
        if(missingGenes.empty?)
          $stderr.debugPuts(__FILE__, __method__, "DEBUG", "no missing genes")
          subDoc = { "items" => geneObjList, "value" => geneObjList.size }
          rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
          fieldMap[:doc] = docId
          fieldMap[:prop] = "ActionabilityDocID.Genes"
          apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq2.notifyWebServer = false 
          apiReq2.bodyFinish {
            headers = apiReq2.respHeaders
            status = apiReq2.respStatus
            apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
          }
          fieldMap[:coll] = @acCurationColl
          apiReq2.put(rsrcPath, fieldMap, JSON.generate(subDoc))
        else
          headers = apiReq.respHeaders
          status = 404
          headers['Content-Type'] = "text/plain"
          msg = "The following genes are either invalid or could not be found in our database: #{missingGenes.join(",")}"
          apiReq.sendToClient(status, headers, JSON.generate({"status" => {"msg" => msg, "statusCode" => status}}))
        end
        
      rescue => err
        headers = apiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        $stderr.debugPuts(__FILE__, __method__, "ERROR", "#{err}\nTRACE:\n#{err.backtrace.join("\n")}")
        apiReq.sendToClient(status, headers, JSON.generate({"status" => {"msg" => err, "statusCode" => status}}))
      end
      
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  

  def status()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/ver/HEAD"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        statusDoc = apiReq.respBody['data']
        resp = nil
        if(statusDoc)
          resp = constructStatusRespObj(statusDoc, fieldMap)
        else
          resp = apiReq.respBody
        end
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        apiReq.sendToClient(status, headers, JSON.generate(resp))
      rescue => err
        headers = apiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        apiReq.sendToClient(status, headers, JSON.generate({"status" => {"msg" => err, "statusCode" => status}}))
      end
      
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  

  
  
end
