class GenboreeAcDocController < ApplicationController
  include GenboreeAcDocHelper

  unloadable

  SEARCH_LIMIT = 20
  before_filter :find_project, :genboreeAcSettings, :find_settings
  
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
        targetHost = getHost()
        gbGroup = getGroup()
        gbkb = getKb()
        fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => @acCurationColl, :doc => docId } 
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
        apiReq.put(rsrcPath, fieldMap, JSON.generate(kbd))
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
          apiReq0 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq0.bodyFinish {
            status = apiReq0.respStatus
            headers = apiReq0.respHeaders
            headers['Content-Type'] = "text/plain"
            # Update the actionability doc with the ref file if everything went fine
            if(status >= 200 and status <=399)
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
                  apiReq3 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
                  apiReq3.bodyFinish {
                    headers = apiReq3.respHeaders
                    status = 200
                    headers['Content-Type'] = "text/plain"
                    if(apiReq3.respStatus >= 200 and apiReq3.respStatus <= 399)
                      apiReq3.respBody["success"] = true
                    else
                      status =  apiReq3.respStatus 
                    end
                    `rm -f #{uploadFilePath}`
                    apiReq2.sendToClient(status, headers, JSON.generate(apiReq3.respBody))
                  }
                  apiReq3.put(rsrcPath, fieldMap, JSON.generate(kbd))
                rescue => err
                  headers = apiReq2.respHeaders
                  status = 500
                  headers['Content-Type'] = "text/plain"
                  apiReq2.sendToClient(status, headers, JSON.generate({"status" => { "msg" => err, "statusCode" => 500}}))
                end
              }
              apiReq2.get(rsrcPath, fieldMap)
            else
              apiReq.sendToClient(status, headers, JSON.generate(apiReq0.respBody))
            end
          }
          apiReq0.put(rsrcPath, fieldMap, File.open(uploadFilePath))
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
  
  def saveGeneDiseasePairInfo()
    rsrcPath  = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    gdp = JSON.parse(params['geneDiseasePairs'])
    # Get document and update 'Gene' property with the user payload
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId } 
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        if(status >= 200 and status < 400)
          kbd = BRL::Genboree::KB::KbDoc.new(apiReq.respBody['data'])
          genes = kbd.getPropItems("ActionabilityDocID.Genes")
          genes.each { |gobj|
            kbGDoc =  BRL::Genboree::KB::KbDoc.new(gobj)
            gene = kbGDoc.getPropVal('Gene')
            geneDocProps = kbGDoc.getPropProperties('Gene')
            if(gdp.key?(gene))
              omims = gdp[gene]
              syndromeOmimDocs = []
              omims.each { |omim|
                syndromeOmimDocs << { "OMIM" => { "value" => omim } }
              }
              geneDocProps['SyndromeOMIMs'] = { "items" => syndromeOmimDocs }
            else
              geneDocProps.delete('SyndromeOMIMs')
            end
          }
          apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq2.bodyFinish {
            headers = apiReq2.respHeaders
            status = apiReq2.respStatus
            apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))  
          }
          apiReq2.put(rsrcPath, fieldMap, JSON.generate(kbd))
        else
          headers['Content-Type'] = "text/plain"
          respBody = JSON.generate(apiReq.respBody)
          apiReq.sendToClient(status, headers, respBody)
        end
      rescue => err
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        resp = { "status" => { "statusCode" => 500, "msg" => err }}
        apiReq.sendToClient(500, headers, JSON.generate(resp))
      end
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  
  def saveSyndromeInfo()
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    subdoc    = params['subdoc']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => "ActionabilityDocID.Syndrome" }
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
    apiReq.put(rsrcPath, fieldMap, subdoc)
  end
  
  def saveStatusInfo()
    tt = Time.now.to_f
    collName   = params['acCurationColl']
    docId      = params['docIdentifier']
    status     = params['status']
    releaseDoc = JSON.parse(params['releaseDoc'])
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    # When releasing document, we will update status and release properties.
    # After inserting working KB document, we'll insert the doc into the release KB with the revision number in the working KB and finally we'll make another insert in the working KB with the revision number in the release KB.
    if(status == 'Released' or status == "Retracted")
      # Because the original code "falls through" at the end of its tasks and is not callback based,
      #   we have to do any async stuff needed MUCH later now, up front, because by the time the release code
      #   has does its job (it's not api based, hacked in) it has stopped respecting callbacks.
      # So let's make sure we have the kbdoc with info about template sets since that will be needed (much later)
      #   to render doc-released messages. This makes @templateSetsDoc available, mainly from useful helper methods.
      loadTemplateSetsDoc( env, @project ) { |result|
        $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Iniital setup and loaded template sets info KbDoc in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
        if( result.is_a?(Hash) and !result.key?(:err) and result[:obj].is_a?(BRL::Genboree::KB::KbDoc) )
          # Let's also get model. Having @model is useful and necessary MUCH later, but as above we need to get these things
          #   before the code stops being callback based and just does direct sendToClient() from almost every method.
          getModelAsync(collName) { |model|
            if( model.is_a?(Hash) )
              # Got model for this kind of doc
              @model = model
              $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Got model in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f

              # Ok, now get and modify doc, and release it. Bit slow to do this.
              rsrcPath = '/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true'
              fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId }
              apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
              apiReq.bodyFinish {
                begin
                  kbd = BRL::Genboree::KB::KbDoc.new(apiReq.respBody['data'])
                  if(status == "Released")
                    revisionNo = apiReq.respBody['metadata']['revision']
                    kbd.setPropVal("ActionabilityDocID.Status", "Released")
                    kbdProps = kbd.getPropProperties("ActionabilityDocID")
                    pairedKbRevision = revisionNo
                    if(kbdProps.key?("Release"))
                      pairedKbRevision = kbd.getPropVal("ActionabilityDocID.Release.kbRevision-PairedKB")
                    end
                    kbdProps["Release"] = releaseDoc['Release']
                    kbd.setPropVal("ActionabilityDocID.Release.kbRevision-PairedKB", pairedKbRevision)
                    $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Got curation track doc and made edits in #{Time.now.to_f - tt}") ; tt = Time.now.to_f
                    apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
                    apiReq2.bodyFinish {
                      # Update doc
                      headers = apiReq2.respHeaders
                      status = apiReq2.respStatus
                      headers['Content-Type'] = "text/plain"
                      if(apiReq2.respStatus >= 200 and apiReq2.respStatus < 400)
                        insertedKbDoc = BRL::Genboree::KB::KbDoc.new(apiReq2.respBody['data'])
                        pairedRevision = apiReq2.respBody['metadata']['revision']
                        insertedKbDoc.setPropVal("ActionabilityDocID.Release.kbRevision-PairedKB", pairedRevision)
                        $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Uploaded edited curation track doc, about to upload the released version in #{Time.now.to_f - tt}") ; tt = Time.now.to_f
                        initUploadReleaseDoc( insertedKbDoc )
                      else
                        apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
                      end
                    }
                    apiReq2.put(rsrcPath, fieldMap, JSON.generate(kbd))
                  else # Retracted
                    kbdProps = kbd.getPropProperties("ActionabilityDocID")
                    kbdProps.delete("Release")
                    kbd.setPropVal("ActionabilityDocID.Status", status)
                    apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
                    apiReq2.bodyFinish {
                      rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/doc/{doc}"
                      fieldMap = { :coll => @acCurationColl, :doc => docId }
                      apiReq3 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
                      apiReq3.bodyFinish {
                        headers = apiReq3.respHeaders
                        status = apiReq3.respStatus
                        headers['Content-Type'] = "text/plain"
                        respBody = JSON.generate(apiReq3.respBody)
                        @releaseKbDoc = kbd
                        notifyOk = notifyDocReleased()
                        $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Done doc-release MQ notification (ok? #{notifyOk.inspect})") 
                        apiReq3.sendToClient(status, headers, respBody)
                      }
                      apiReq3.delete(rsrcPath, fieldMap)
                    }
                    apiReq2.put(rsrcPath, fieldMap, JSON.generate(kbd))
                  end
                rescue => err
                  headers = apiReq.respHeaders
                  status = apiReq.respStatus
                  headers['Content-Type'] = "text/plain"
                  resp = { "status" => { "statusCode" => 500, "msg" => err }}
                  $stderr.debugPuts(__FILE__, __method__, "ERROR", "#{err}\n\nTRACE:\n#{err.backtrace.join("\n")}")
                  apiReq.sendToClient(500, headers, JSON.generate(resp))
                end
              }
              # Get the doc
              apiReq.get(rsrcPath, fieldMap)
            else # error probably
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
    else 
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
      fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :prop => "ActionabilityDocID.Status" }
      apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq.bodyFinish {
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
      }
      payload = { "value" => status }
      apiReq.get(rsrcPath, fieldMap, JSON.generate(payload))
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
  
  def reopen()
    docId     = params['docIdentifier']
    updateReleasedDoc = params['updateReleasedDoc']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => @acCurationColl, :doc => docId, :prop => "ActionabilityDocID.Status" }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      begin
        # Update the released doc as well
        if(updateReleasedDoc == "true")
          # Do set up for messaging
          loadTemplateSetsDoc( env, @project ) { |result|
            if( result.is_a?(Hash) and !result.key?(:err) and result[:obj].is_a?(BRL::Genboree::KB::KbDoc) )
              # Let's also get model. Having @model is useful and necessary MUCH later, but as above we need to get these things
              #   before the code stops being callback based and just does direct sendToClient() from almost every method.
              getModelAsync(@acCurationColl) { |model|
                if( model.is_a?(Hash) )
                  @model = model
                  apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
                  apiReq2.bodyFinish {
                    headers = apiReq2.respHeaders
                    status = apiReq2.respStatus
                    headers['Content-Type'] = "text/plain"
                    if(status >= 200 and status < 400)
                      apiReq3 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
                      apiReq3.bodyFinish {
                        headers = apiReq3.respHeaders
                        status = apiReq3.respStatus
                        headers['Content-Type'] = "text/plain"
                        @releaseKbDoc = BRL::Genboree::KB::KbDoc.new(apiReq3.respBody['data'])
                        notifyOk = notifyDocReleased()
                        $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Done doc-release MQ notification (ok? #{notifyOk.inspect})")
                        apiReq3.sendToClient(status, headers, JSON.generate(apiReq3.respBody))
                      }
                      rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/doc/{doc}"
                      fieldMap = {:coll => @acCurationColl, :doc => docId}
                      apiReq3.get(rsrcPath, fieldMap)
                    else
                      apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody))
                    end
                  }
                  payload = { "value" => "Released - Under Revision" }
                  rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/doc/{doc}/prop/{prop}"
                  fieldMap = {:coll => @acCurationColl, :doc => docId, :prop => "ActionabilityDocID.Status"}
                  $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "rsrcPath: #{rsrcPath.inspect}; fieldMap: #{fieldMap.inspect}")
                  apiReq2.put(rsrcPath, fieldMap, JSON.generate(payload))
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
            else
              err = ( result[:err].message or IOError.new( "ERROR: could not retrieve the KbDoc with info about the various TemplateSets that are available." ) )
              headers = @lastApiReq.respHeaders rescue []
              status = @lastApiReq.respStatus rescue 500
              headers['Content-Type'] = 'application/json'
              resp = { "status" => { "statusCode" => status, "msg" => err.message } }
              $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Get template sets info KbDoc failed and info logged. Returning error payload:\n\t#{resp.to_json}")
              @lastApiReq.sendToClient(status, headers, resp.to_json)
            end
          }
          
        else
          apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
        end
      rescue => err
        resp = { "status" => { "statusCode" => 500, "msg" => err }}
        apiReq.sendToClient(500, headers, JSON.generate(resp))
      end
    }
    payload = { "value" => "Released - Under Revision" }
    apiReq.put(rsrcPath, fieldMap, JSON.generate(payload))
  end

  def status()
    # To avoid getting WHOLE CONTENT doc unnecessarily, we specify the content fieds via contentFields param.
    # * By default, doc/{docId}/vers will also give you 3 the values for version metadata properties:
    #   * versionNum
    #   * versionNum.timestamp
    #   * versionNum.author
    # * Also by default we'll be getting the values themselves for the version and content fields, not the full
    #   value objects.
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/ver/HEAD?detailed=true&contentFields={cf}"
    contentFields = [ 'ActionabilityDocID.Status' ]
    collName  = params['acCurationColl']
    docId     = params['docIdentifier']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId, :cf => contentFields }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        statusDoc = apiReq.respBody['data']
        #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "statusDoc:statusDoc:\n\n#{JSON.pretty_generate(statusDoc) rescue statusDoc.inspect}\n\n")
        resp = nil
        if(statusDoc)
          resp = { "data" => {} }
          kbDoc = BRL::Genboree::KB::KbDoc.new(statusDoc)
          author = kbDoc.getPropVal('versionNum.author')
          apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq2.bodyFinish {
            begin
              userRec = nil
              if(apiReq2.respBody['data'])
                userRec = apiReq2.respBody['data']
              end
              resp['data']['lastEditedBy'] = "#{userRec['firstName']} #{userRec['lastName']}"
              contentDoc = BRL::Genboree::KB::KbDoc.new(kbDoc.getPropVal('versionNum.content'))
              resp['data']['status'] = contentDoc.getPropVal('ActionabilityDocID.Status')
              headers = apiReq2.respHeaders
              status = apiReq2.respStatus
              headers['Content-Type'] = "text/plain"
              apiReq2.sendToClient(status, headers, JSON.generate(resp))
            rescue => err
              sendResp(apiReq2, { "status" => { "msg" => err } }, 500)
            end
          }
          rsrcPath = "/REST/v1/usr/{usr}?connect=false"
          apiReq2.get(rsrcPath, { :usr => author })
        else
          resp = apiReq.respBody
          headers = apiReq.respHeaders
          status = apiReq.respStatus
          headers['Content-Type'] = "text/plain"
          apiReq.sendToClient(status, headers, JSON.generate(resp))
        end
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
