require 'time'

class GenboreeAcUiDocsStatusController < ApplicationController
  include GenboreeAcDocHelper
  include GenboreeAcHelper::PermHelper
  include GbMixin::AsyncRenderHelper
  unloadable
  layout 'ac_bootstrap_extensive_hdr_ftr'
  # @todo No, :genboreeAcSettings should be removed [even from SVN] ; the generic find_settings has long been available and should be used.
  before_filter :find_project, :genboreeAcSettings, :authorize, :find_settings
  respond_to :json

  def show()
    # @todo dynamically set @removeLayout from database record
    @docIdentifier = params['doc'] || nil
    @errMsg = "Unknown Error. Please contact the project administrator to resolve this issue."
    @errorFound = false

    # What *content* fields to get for each version record?
    # - Include Item root props or Item sub-probs if you want values for those
    # - By default, will get just the VALUES of listed fields rather than getting whole
    #   subtrees that include stuff that YOU DON'T NEED.
    # - If you need subtrees (often don't, even for item lists where you just specify the item
    #   root prop and specific item subprops you need the value for), maybe because you iterate
    #   over the various props rather than be specific about which you need, then provide contentFieldsValue=valueObj
    contentFields = [
      "ActionabilityDocID",
      "ActionabilityDocID.Release",
      "ActionabilityDocID.Syndrome",
      "ActionabilityDocID.Genes.Gene",
      "ActionabilityDocID.Stage 2.Outcomes",
      "ActionabilityDocID.Status",
      "ActionabilityDocID.Stage 1.Final Stage1 Report.Status"
    ]
    # By default, doc/{docId}/vers will also give you 3 the values for version metadata properties:
    # * versionNum
    # * timestamp
    # * author
    # If these are not sufficient (or too much) provide your own list via versionFields={vf} parameter to URL.
    # These are separate from the *content* [doc] fields.

    # What normal/large col grid sizes to use?
    # - Use instance variable to coordinate with partials that needs same/sync'd info
    @colSizes = {
      :md => {
        :syndrome        => 'col-md-3',
        :genes           => 'col-md-2',
        :lastEdited      => 'col-md-2',
        :status          => 'col-md-5'
        #:actions         => 'col-md-2'
      }
    }
    
    @matchOrderByStrToProps = {
      #"syndrome-gene" => ["ActionabilityDocID.Syndrome", "ActionabilityDocID.Genes.Gene"],
      #"gene-syndrome" => ["ActionabilityDocID.Genes.Gene", "ActionabilityDocID.Syndrome"],
      "syndrome" => ["ActionabilityDocID.Syndrome", "ActionabilityDocID.Genes.Gene"],
      "gene" => ["ActionabilityDocID.Genes.Gene", "ActionabilityDocID.Syndrome"],
      "status" => ["ActionabilityDocID.Status"]
    }
    
    @activeCurationStatus = ["Entered", "Reviewing", "Collecting", "In Preparation", "Released - Under Revision"]

    @genboreeAc = GenboreeAc.find_by_project_id(@projectId)
    @userPermsJS = pluginUserPerms(:genboree_ac, @project, @currRmUser, :as => :javascript)
    @userPermsObj = pluginUserPerms(:genboree_ac, @project, @currRmUser)
    @litSearchSourceJSON = getLitSearchSourceHashJSON()
    @partialOnly = ( (params.key?("partialOnly") and params["partialOnly"] == 'true') ? true : false )
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    initRackEnv( env ) 
    controller = self
    @showLimit = 50
    # Ajax param
    @showStatus = ( params.key?('showStatus') ? params['showStatus'] : 'all' )
    # URL param. Override @showStatus if present
    if(params.key?('status'))
      @showStatus = params['status'] 
    end
    # Ajax param
    @matchOrderByStr = (params.key?("matchOrderByStr") ? params["matchOrderByStr"] : "syndrome")
    # URL param. Override @matchOrderByStr if present
    if(params.key?("sortBy"))
      @matchOrderByStr = params["sortBy"]
    end
    # Ajax and URL
    @queryTerm = (params.key?("queryTerm") ? params["queryTerm"] : "")
    @matchOrderBy = @matchOrderByStrToProps[@matchOrderByStr]
    @skip = ( params.key?('skip') ? params['skip'].to_i : 0 )
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true&viewFields={vf}&skip={skip}&matchOrderBy={matchOrderBy}"
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => @acCurationColl, :vf => contentFields, :skip => @skip, :limit => @showLimit, :matchOrderBy => @matchOrderBy }
    matchProps = []
    matchVals = []
    mpAdded = false
    # If specific query term specified, get all matching records. Otherwise limit. Filter will be applied later
    if(@queryTerm != "")
      rsrcPath << "&matchProps={mp}&matchValue={mv}"
      rsrcPath << "&matchMode=keyword"
      matchProps << "ActionabilityDocID.Syndrome"
      matchProps << "ActionabilityDocID.Genes.Gene"
      matchVals << @queryTerm
      mpAdded = true
    else
      rsrcPath << "&limit={limit}"
      if(@showStatus != 'all')
        rsrcPath << "&matchProp={mp}&matchValues={mv}"
        matchProps << "ActionabilityDocID.Status"
        if(@showStatus == "Undergoing active curation")
          @activeCurationStatus.each { |ss|
            matchVals << ss  
          }
        else
          matchVals << @showStatus
        end
        mpAdded = true
      end
    end
    if(mpAdded)
      fieldMap[:mp] = matchProps
      fieldMap[:mv] = matchVals
    end
    @endReached = false
    @totalDocs = 0
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        status = apiReq.respStatus
        if(status >= 200 and status < 400)
          docs = apiReq.respBody['data']
          @viewObj = []
          docIDs = []
          docs.each { |doc|
            kbd = BRL::Genboree::KB::KbDoc.new(doc)
            docStatus = kbd.getPropVal("ActionabilityDocID.Status")
            if(@queryTerm != "")
              if(@showStatus != 'all')
                if(@showStatus == "Undergoing active curation")
                  if(docStatus == "Released")
                    next
                  end
                else
                  if(docStatus != @showStatus)
                    next
                  end
                end
              end
            end
            docId = kbd.getPropVal("ActionabilityDocID")
            docIDs << docId
            syndrome = kbd.getPropVal("ActionabilityDocID.Syndrome")
            geneList = kbd.getPropItems("ActionabilityDocID.Genes")
            genes = []
            geneList.each { |gg|
              genes << gg['Gene']['value']  
            }
            
            kbdProps = kbd.getPropProperties("ActionabilityDocID")
            stage1Status = "Incomplete"
            if(kbdProps.key?("Stage 1"))
              stage1Props = kbd.getPropProperties("ActionabilityDocID.Stage 1")
              if(stage1Props.key?("Final Stage1 Report"))
                stage1Status = kbd.getPropVal("ActionabilityDocID.Stage 1.Final Stage1 Report.Status")
              end
            end
            @viewObj << {"docId" => docId, "syndrome" => syndrome, "genes" => genes, "stage1Status" => stage1Status, "docStatus" => docStatus}
          }
          if(docIDs.empty?)
            if(@partialOnly)
              renderToClient(controller, {:partial => "genboree_ac_ui_docs_status/docs_status_records", :layout => false})
            else
              @totalDocs = 0
              renderToClient(controller)
            end
          else
            # Get the total number of docs if @skip=0 and no query term specified 
            if(@skip == 0 and @queryTerm == "")
              rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=false"
              if(@showStatus != 'all')
                rsrcPath << "&matchProp={mp}&matchValues={mv}"
                fieldMap[:mp] = "ActionabilityDocID.Status"
                fieldMap[:mv] = (@showStatus == "Undergoing active curation" ? @activeCurationStatus : @showStatus )
              end
              apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
              apiReq2.bodyFinish {
                begin
                  @totalDocs = apiReq2.respBody['data'].size
                  getVersionDocs(docIDs)
                rescue => err
                  headers = apiReq2.respHeaders
                  status = 500
                  headers['Content-Type'] = "text/plain"
                  $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Exception raised.\n  - Error Class: #{err.class}\nError Message: #{err.message}\n  - Error Trace:\n#{err.backtrace.join("\n")}")
                  @errMsg = err.message
                  @errorFound = true
                  if(@partialOnly)
                    errorResp = createErrorRespObj(@errMsg, status)
                    apiReq2.sendToClient(status, headers, errorResp)
                  else
                    renderToClient(controller)
                  end
                end
              }
              apiReq2.get(rsrcPath, fieldMap)
            else
              getVersionDocs(docIDs)
            end
          end
        else
          headers = apiReq.respHeaders
          status = apiReq.respStatus
          headers['Content-Type'] = "text/plain"
          @errMsg = "Unknown Error. It is possible the API server is down or being restarted."
          if(apiReq.respBody.respond_to?(:key?) and apiReq.respBody.key?("status") and apiReq.respBody['status'].key?('msg'))
            @errMsg = apiReq.respBody['status']['msg']
          end
          @errorFound = true
          if(@partialOnly)
            errorResp = createErrorRespObj(@errMsg, status)
            apiReq.sendToClient(status, headers, errorResp)
          else
            renderToClient(controller)
          end
        end
      rescue => err
        @viewObj = []
        #$stderr.puts "ERROR - #{__method__}() => Exception! #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}\n\n"
        headers = apiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Exception raised.\n  - Error Class: #{err.class}\nError Message: #{err.message}\n  - Error Trace:\n#{err.backtrace.join("\n")}")
        @errMsg = err.message
        @errorFound = true
        if(@partialOnly)
          errorResp = createErrorRespObj(err.message, status)
          apiReq.sendToClient(status, headers, errorResp)
        else
          renderToClient(controller)
        end
      end
    }
    $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "rsrcPath: #{rsrcPath.inspect}\nfieldMap: #{fieldMap.inspect}")
    apiReq.get(rsrcPath, fieldMap)
    
  end
  
  # Helpers
  
  def createErrorRespObj(msg, status)
    return JSON.generate({"status" => {"statusCode" => status, "msg" => msg}})
  end
  
  def getVersionDocs(docIDs)
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    controller = self
    versionHash = {}
    gbGroup = getGroup()
    gbkb = getKb()
    #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "docIds:\n#{docIDs}")
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs/ver/HEAD?docIDs={docIDs}"
    fieldMap = {:grp => gbGroup, :kb=> gbkb, :coll => @acCurationColl, :docIDs => docIDs}
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        if(status >= 200 and status < 400)
          headers['Content-Type'] = "text/plain"
          status = apiReq.respStatus
          versDocs = apiReq.respBody['data']
          if(versDocs)
            #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "versDocs:\n#{JSON.pretty_generate(versDocs)}")
            versDocs.each{ |ver|
              versionHash[ver.keys.first] = ver[ver.keys.first]['data']
            }
            idx = 0
            docIDs.each {|docId|
              if(versionHash.key?(docId))
                @viewObj[idx]["lastEdited"] = versionHash[docId]['versionNum']['properties']['timestamp']['value'].split(/\s*-/).first
              end
              idx += 1
            }
            if(@partialOnly)
              renderToClient(controller, {:partial => "genboree_ac_ui_docs_status/docs_status_records", :layout => false})
            else
              renderToClient(controller)
            end
          else
            if(@partialOnly)
              renderToClient(controller, {:partial => "genboree_ac_ui_docs_status/docs_status_records", :layout => false})
            else
              renderToClient(controller)
            end
          end
        else
          headers = apiReq.respHeaders
          status = apiReq.respStatus
          headers['Content-Type'] = "text/plain"
          @errMsg = "Unknown Error. It is possible the API server is down or being restarted."
          if(apiReq.respBody.respond_to?(:key?) and apiReq.respBody.key?("status") and apiReq.respBody['status'].key?('msg'))
            @errMsg = apiReq.respBody['status']['msg']
          end
          @errorFound = true
          if(@partialOnly)
            errorResp = createErrorRespObj(@errMsg, status)
            apiReq.sendToClient(status, headers, errorResp)
          else
            renderToClient(controller)
          end
        end
      rescue => err
        @viewObj = []
        #$stderr.puts "ERROR - #{__method__}() => Exception! #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}\n\n"
        headers = apiReq.respHeaders
        status = 500
        headers['Content-Type'] = "text/plain"
        $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Exception raised.\n  - Error Class: #{err.class}\nError Message: #{err.message}\n  - Error Trace:\n#{err.backtrace.join("\n")}")
        @errMsg = err.message
        @errorFound = true
        if(@partialOnly)
          errorResp = createErrorRespObj(@errMsg, status)
          apiReq.sendToClient(status, headers, errorResp)
        else
          renderToClient(controller)
        end
      end
    }
    apiReq.get(rsrcPath, fieldMap)
  end

  

end
