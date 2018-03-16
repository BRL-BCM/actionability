require 'yaml'
require 'json'
require 'uri'
require 'em-http-request'
require 'brl/util/util'
require 'brl/db/dbrc'
require 'brl/rest/apiCaller'
require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/kb/propSelector'
require 'brl/genboree/kb/producers/trimmedDocProducer'
require 'plugins/genboree_ac/app/helpers/host_auth_map_helper'
require 'plugins/genboree_ac/app/helpers/genboreeAc_perm_helper'
require 'plugins/genboree_ac/app/helpers/litSearchHelper'
require 'plugins/genboree_ac/app/helpers/db_connect'

module GenboreeAcHelper

  # Make additional before_filter methods available from genboree_generic plugin.
  include GenericHelpers::BeforeFiltersHelper
  include GenericHelpers::PermHelper
  include PluginHelpers::BeforeFiltersHelper
  include ProjectHelpers::BeforeFiltersHelper
  include PluginHelpers::PluginSettingsHelper
  extend  PluginHelpers::PluginSettingsHelper  # so also available as "class" method when doing settings
  include LitSearchHelper
  include GenboreeAcHelper::TemplateSetHelper

  # Ensure certain key helpers that are (a) included by this module AND (b) which contain methods
  #   we want available in Views, are EXPLICITLY included by the Controller, so as to trigger their
  #   automatic helper_method registration. Otherwise, while the methods will be available to the
  #   Controller (because included here), they WILL NOT BE available to any VIEWS without doing
  #   this to arrage the auto-registration of helper_methods.
  def self.included(includingClass)
    includingClass.send(:include, GenericHelpers::PermHelper)
  end

  BOUNDARY_EXTRACTOR = /boundary\s*=\s*([^; \t\n]+)/
  PLUGIN_SETTINGS_MODEL_CLASS = GenboreeAc
  PLUGIN_PROJ_SETTINGS_FIELDS = [
    :useRedmineLayout,
    :gbHost,
    :gbGroup,
    :gbKb,
    :headerIncludeFileLoc,
    :footerIncludeFileLoc,
    :gbActCurationColl,
    :gbActRefColl,
    :gbActGenesColl,
    :gbActOrphanetCollRsrcPath,
    :gbReleaseKbRsrcPath,
    :gbTemplateSetsColl,
    :gbUrlMountDir,
    :isAcReleaseTrack
  ]

  # ----------------------------------------------------------------
  # BEFORE_FILTERS - use by symbol with the before_filter Rails method in your controller
  # ----------------------------------------------------------------
  # This should be defined in a global helper. Not buried.
  # Must have @project set before calling Redmine's authorize before_filter.
  # Must have @project set before certain other plugin filters.
  # Typical way to handle this is to register this before_filter first, before other before_filters.

  def docIdentifier()
    @docIdentifier = params['doc']
    @docIdentifier = nil if(@docIdentifier and @docIdentifier !~ /\S/)
    return @docIdentifier
  end

  def genboreeAcSettings()
    kbProjectSettings()
    @genboreeAc = @pluginProjSettings
    @acCurationColl = @genboreeAc.actionabilityColl.to_s.strip
    @acRefColl = @genboreeAc.referencesColl.to_s
    @acGenesColl = @genboreeAc.genesColl.to_s
    @acOrphanetCollRsrcPath = @genboreeAc.gbActOrphanetCollRsrcPath
    @gbReleaseKbRsrcPath = @genboreeAc.gbReleaseKbRsrcPath
    @acTemplateSetsColl = @genboreeAc.templateSetsColl.to_s.strip
    @urlMountDir = @genboreeAc.urlMountDir.to_s.strip
    return @genboreeAc
  end

  # ----------------------------------------------------------------
  # OTHER COMMON HELPER METHODS
  # ----------------------------------------------------------------
  # Leverage existing rails functionality for 404 in a simple way.
  # * Useful because it will also interrupt your code processing while triggering rails handling
  # * Because this raises an exception, it _interrupts_ your code/processing immediately, and
  #   activates Rails' handling. This makes it better for writing controllers and such than other
  #   404 techniques (e.g. it's better than render_404 because of this)
  def notFound()
    raise ActionController::RoutingError.new('Not Found')
  end

  def addProjectIdToParams()
    prjRec = Project.find(params['id'])
    params['project_id'] = prjRec.id
  end

  def getUserInfo(gbKbHost)
    #dbKey = (gbHost == '10.15.5.109' ? "DB:10.15.5.109" : "DB:taurine.brl.bcmd.bcm.edu")
    gbAuthHost = getGbAuthHostName()
    dbconn = getDbConn(gbAuthHost)
    login = @currRmUser.login
    retVal = dbconn.getUserByName(login)
    # NO: Must cease doing this 'project_id' param approach. STOP adding 'project_id' to params when missing
    #  (basically forcing a bad approach inherited from genbore_kb). Go through @project or @projectId--see find_project
    #  and note that it, and several other methods here, are useful as before_filters to get a standard env.
    #@project = Project.find(params['project_id']) # <= bad
    #$stderr.puts "@project: #{@project.inspect}\n login: #{login.inspect}\n retVal: #{retVal.inspect}"
    if(!retVal.nil? and !retVal.empty? and @currRmUser.member_of?(@project))
      userInfo = GenboreeAcHelper::HostAuthMapHelper.getHostAuthMapForUserAndHostName(retVal, gbKbHost, gbAuthHost, dbconn)
      retVal = userInfo
    else
      if(@project.is_public == true)
        retVal = [:anon, :anon]
      else
        retVal =  [ nil, nil ]
      end
    end
    return retVal
  end

  # Host name of the Genboree instance providing authorization service
  # for this Redmine.
  def getGbAuthHostName()
    retVal = nil
    gbAuthSrcs = AuthSourceGenboree.where( :name => "Genboree" )
    if(gbAuthSrcs and !gbAuthSrcs.empty?)
      gbAuthSrc = gbAuthSrcs.first
      retVal = gbAuthSrc.host
    end
    return retVal
  end

  def getDbConn(gbAuthHost=nil)
    gbAuthHost = getGbAuthHostName() unless(gbAuthHost)
    dbKey = "DB:#{gbAuthHost}"
    dbconn = GenboreeAcHelper::DbConnect.new(dbKey)
    return dbconn
  end

  def getHost()
    @genboreeAc = GenboreeAc.find_by_project_id(@project)
    return @genboreeAc.gbHost
  end

  def getGroup()
    @genboreeAc = GenboreeAc.find_by_project_id(@project)
    return @genboreeAc.gbGroup.strip
  end
  
  def getKb()
    @genboreeAc = GenboreeAc.find_by_project_id(@project)
    return @genboreeAc.gbKb.strip
  end

  def getModel(collName)
    $stderr.debugPuts(__FILE__, __method__, 'DEPRECATED - BLOCKING', "This method has been deprecated because it is *blocking*. A non-blocking approach is available and should be used instread. See GenboreeAcAsyncHelper#getModelAsync().")
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model"
    fieldMap = { :coll => collName }
    apiResult  = apiGet(rsrcPath, fieldMap)
    if(apiResult[:respObj]['data'])
      retVal = apiResult[:respObj]['data']
    else
      retVal = nil
    end
    return retVal
  end

  def getGbAccount(login)
    rsrcPath = "/REST/v1/usr/{usr}?connect=false"
    fieldMap = { :usr => login }
    apiResult  = apiGet(rsrcPath, fieldMap)
    if(apiResult[:respObj]['data'])
      retVal = apiResult[:respObj]['data']
    else
      retVal = nil
    end
    return retVal
  end

  # Gets them all, in order they appear, even if there are duplicates. Use uniq! if you want to remove dups.
  def extractReferenceIDs(kbDoc)
    kbDoc = BRL::Genboree::KB::KbDoc.new(kbDoc) unless(kbDoc.is_a?(BRL::Genboree::KB::KbDoc))
    refIds = []
    # Find prop paths that contain reference lists
    refListProps = kbDoc.getMatchingPaths(/References$/)
    # For each matching path, get the sub items (if any) and extract the refDocID from the Reference value
    refListProps.each { |refsPath|
      refItems = kbDoc.getPropItems(refsPath)
      if(refItems)
        refItems.each { |refItem|
          refSubDoc = BRL::Genboree::KB::KbDoc.new(refItem)
          refVal = refSubDoc.getRootPropVal()
          if(refVal and !refVal.empty?)
            refId = refVal.split('/').last
            refIds << refId
          end
        }
      end
    }
    return refIds
  end

  # Gets them all, in order they appear, even if there are duplicates. Use uniq! if you want to remove dups.
  def extractGbAccounts(kbDoc, model)
    kbDoc = BRL::Genboree::KB::KbDoc.new(kbDoc) unless(kbDoc.is_a?(BRL::Genboree::KB::KbDoc))
    gbAccounts = []
    # Get helpful path selectors covering props that have gbAccount domain
    modelHelper = BRL::Genboree::KB::Helpers::ModelsHelper.new(model)
    gbAccountSelectors = modelHelper.getPropPathsForDomain(model, 'gbAccount', { :selectorCompatible => true })
    # Select ALL the actual prop values using the selectors (selector approach digs out ALL the ones appearing in items lists)
    selector = BRL::Genboree::KB::PropSelector.new(kbDoc)
    gbAccountSelectors.each { |pathSel|
      # Get all the values from paths matching the pathSel
      vals = selector.getMultiPropValues(pathSel) rescue nil
      if(vals and !vals.empty?)
        gbAccounts += vals
      end
    }
    return gbAccounts
  end

  def lookupRefDocs(refDocIds)
    $stderr.debugPuts(__FILE__, __method__, 'DEPRECATED - BLOCKING', "This method has been deprecated because it is *blocking*. A non-blocking approach is available and should be used instread. See GenboreeAcAsyncHelper#getDocRefsAsync().")
    refDocs = []
    if(refDocIds and refDocIds.size > 0)
      uniqRefIds = refDocIds.uniq
      #$stderr.debugPuts(__FILE__, __method__, "STATUS", "The doc #{@kbDoc.getRootPropVal().inspect} has #{refDocIds.size} reference mentions ; #{uniqRefIds.inspect.size} unique reference docs.")
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?matchProp=Reference&matchMode=exact&detailed=true&matchValues={vals}"
      fieldMap  = { :coll => @acRefColl, :vals => uniqRefIds }
      refApiResult = apiGet(rsrcPath, fieldMap)
      if(refApiResult[:respObj]['data'])
        refDocs = refApiResult[:respObj]['data']
      else
        $stderr.debugPuts(__FILE__, __method__, "ERROR", "Failed API Get?\n\n#{JSON.pretty_generate(refApiResult[:respObj])}")
      end
    end
    return refDocs
  end

  # @todo One request per login. May be slow if many logins in doc. May need support for /REST/v1/usrs + testEntity payload so can do 1 request
  def lookupGbAccounts(logins)
    gbAccounts = []
    if(logins and logins.size > 0)
      uniqLogins = logins.uniq
      #$stderr.debugPuts(__FILE__, __method__, "STATUS", "The doc #{@kbDoc.getRootPropVal().inspect} has #{logins.size} login mentions ; #{uniqLogins.size} unique logins.")
      uniqLogins.each { |login|
        gba = getGbAccount(login)
        gbAccounts << gba unless(gba.nil? or gba.empty?)
      }
    end
    return gbAccounts
  end

  # ------------------------------------------------------------------
  # KbDoc manipulation / alteration / merger helpers
  # ------------------------------------------------------------------

  # Returns a copy of the KbDoc in which all empty properties/lists are trimmed/stripped.
  # i.e. if the property has no non-nil/non-empty value AND has no non-empty properties nor any
  # non-empty items, then that property is removed from the KbDoc. "Compacted" doc.
  # @note Returned doc may not be valid against its model.
  # @param [BRL::Genboree::KB:KbDoc] kbDoc The doc of which to create a trimmed version.
  # @return [BRL::Genboree::KB::KbDoc] A trimmed/compacted version of the input doc.
  def trimDoc(kbDoc)
    trimmedDocProducer = BRL::Genboree::KB::Producers::TrimmedDocProducer.new(:aggressive => true)
    return trimmedDocProducer.produce(kbDoc)
  end

  def extractAcRefs(kbDoc, opts={ :replaceWithNums => true})
    # Trim/compact the doc to get rid of "empty" properties
    refIds = extractReferenceIDs(kbDoc)
    # Get info for each reference
    if(refIds and !refIds.empty?)
      refDocs = lookupRefDocs(refIds)
      if(refDocs)
        #$stderr.debugPuts(__FILE__, __method__, "STATUS", "Retrived #{@refDocs.size} FULL reference docs for those unique docs.")
        replaceRefLinkWithNums(kbDoc, refIds, refDocs) if(opts[:replaceWithNums])
      else # no refs or something
        refDocs = []
        $stderr.debugPuts(__FILE__, __method__, "ERROR", "Could not get the ref docs for references mentioned in doc #{kbDoc.getRootPropVal().inspect}")
      end
    else
      # No references?
      refDocs = []
      #$stderr.debugPuts(__FILE__, __method__, "WARNING", "The doc #{@kbDoc.getRootPropVal().inspect} has NO reference mentions ??")
    end
    return refDocs
  end

  def extractAcLogins(kbDoc, model, opts={ :replaceWithNames => true})
    logins = extractGbAccounts(kbDoc, model)
    if(logins and !logins.empty?)
      gbAccounts = lookupGbAccounts(logins)
      if(gbAccounts and !gbAccounts.empty?)
        replaceGbAccountWithNames(kbDoc, model, gbAccounts) if(opts[:replaceWithNames])
      else # retrieval failure or something ; none found
        gbAccounts = []
        $stderr.debugPuts(__FILE__, __method__, "ERROR", "Could not get the user account info from Genboree for logins mentioned in doc #{kbDoc.getRootPropVal().inspect}")
      end
    end
    return gbAccounts
  end

  def replaceRefLinkWithNums(kbDoc, refIds, refDocs)
    return replaceRefLinks(kbDoc, refIds, refDocs, :nums)
  end

  def replaceRefLinks(kbDoc, refIds, refDocs, replaceWith=:docIds)
    docIdentifier = kbDoc.getRootPropVal()
    # Sort
    refDocs.map! { |refDoc| BRL::Genboree::KB::KbDoc.new(refDoc) }
    refDocs.sort! { |aa, bb|
      aaId = aa.getRootPropVal()
      bbId = bb.getRootPropVal()
      aaIdx = refIds.index(aaId)
      bbIdx = refIds.index(bbId)
      aaIdx <=> bbIdx
    }
    # Replace References.Reference values with appropriate number from sorting
    # * Because we sort actual refs by order of first appearance, can use its index in the sorted set of all refs
    docRefListProps = kbDoc.getMatchingPaths(/References$/)
    docRefListProps.each { |docRefListProp|
      docRefItems = kbDoc.getPropItems(docRefListProp)
      if(docRefItems)
        docRefItems.each { |docRefItem|
          # For the Reference item in the doc, get the value which will be a relative URI to the reference doc
          docRefSubDoc = BRL::Genboree::KB::KbDoc.new(docRefItem)
          docFullRefId = docRefSubDoc.getRootPropVal()
          # What if empty or nil value or something? How does that happen anyway??
          if(!docFullRefId.nil? and docFullRefId =~ /\S/)
            # Remove prefix, leaving just the Reference doc ID.
            docRefId = docFullRefId.split('/').last
            if(replaceWith == :nums)
              # Find the index of this Reference doc ID in the list of ALL References mentioned in this Actionability document
              docRefIdx = refDocs.find_index { |refDoc|
                refDoc.getRootPropVal() == docRefId
              }
              if(docRefIdx)
                docRefSubDoc.setPropVal("Reference", (docRefIdx+1).to_s)
              else # Fallback if error
                docRefSubDoc.setPropVal("Reference", "Unknown Ref:#{docRefSubDoc.getPropVal('Reference')}")
              end
            else # replaceWith == :docIds (of Reference doc)
              docRefSubDoc.setPropVal('Reference', docRefId)
            end
          else
            $stderr.debugPuts(__FILE__, __method__, "ERROR", "Bad doc #{docIdentifier.inspect} or at least base Reference item under #{docRefListProp.inspect}. Suspect Reference item:\n\n#{JSON.pretty_generate(docRefItem)}\n\n")
          end
        }
      end
    }
    #$stderr.debugPuts(__FILE__, __method__, "STATUS", "Sorted unique reference list by order of APPEARANCE in doc. Replaced reference URIs with appropriate index number in kbDoc.")
    return
  end

  # Resorts the References item lists by their value. Really only useful
  #   if the relative references to the coll/docId have been replaced with numbers
  #   (see #replaceRefLinkWithNums)
  def numericResortRefLists(kbDoc)
    docRefListProps = kbDoc.getMatchingPaths(/References$/)
    docRefListProps.each { |docRefListProp|
      docRefItems = kbDoc.getPropItems(docRefListProp)
      if(docRefItems)
        docRefItems.sort! { |refItemA, refItemB|
          refItemASubDoc = BRL::Genboree::KB::KbDoc.new(refItemA)
          refItemBSubDoc = BRL::Genboree::KB::KbDoc.new(refItemB)
          ( refItemASubDoc.getRootPropVal().to_i <=> refItemBSubDoc.getRootPropVal().to_i ) rescue 0
        }
      end
    }
  end

  def replaceGbAccountWithNames(kbDoc, model, gbAccounts)
    kbDoc = BRL::Genboree::KB::KbDoc.new(kbDoc) unless(kbDoc.is_a?(BRL::Genboree::KB::KbDoc))
    # Get helpful path selectors covering props that have gbAccount domain
    modelHelper = BRL::Genboree::KB::Helpers::ModelsHelper.new(model)
    gbAccountSelectors = modelHelper.getPropPathsForDomain(model, 'gbAccount', { :selectorCompatible => true })
    # Select ALL the actual prop paths using the selectors (selector approach digs out ALL the ones appearing in items lists)
    selector = BRL::Genboree::KB::PropSelector.new(kbDoc)
    gbAccountSelectors.each { |pathSel|
      # Get all the paths matching the pathSel
      paths = selector.getMultiPropPaths(pathSel) rescue nil # Will raise error.
      if(paths)
        paths.each { |path|
          # Get value at path, which is a login
          docLogin = kbDoc.getPropVal(path)
          # See if we have an account record for it
          account = gbAccounts.find { |acct| acct['login'] == docLogin }
          if(account) # Then replace with a displayable name
            userName = "#{account['firstName']} #{account['lastName']}"
            kbDoc.setPropVal(path, userName)
          else
            $stderr.debugPuts(__FILE__, __method__, "ERROR", "There appears to be NO genboree user account with the login #{docLogin.inspect}.")
          end
        }
      end
    }
    return
  end

  # ------------------------------------------------------------------
  # API Helpers
  # ------------------------------------------------------------------
  def apiGet(rsrcPath, fieldMap={}, jsonResp=true, gbHost=nil, payload=nil)
    $stderr.debugPuts(__FILE__, __method__, '!!!!! DEPRECATED - BLOCKING API CALL !!!!!', " - This and the calling code needs to be refactored to non-blocking/async call")
    # Maintain & return a hash of useful fields. We'll pass the needed onces (like :status, :location, etc) to Rails methods as needed.
    retVal = { :respObj => nil, :status => 500 }
    @respObj = nil
    # Get typical generic info

    # NO: Must cease doing this 'project_id' param approach. STOP adding 'project_id' to params when missing
    #  (basically forcing a bad approach inherited from genbore_kb). Go through @project or @projectId--see find_project
    #  and note that it, and several other methods here, are useful as before_filters to get a standard env.
    #@project = Project.find(params['project_id']) # <= bad
    @genboreeAc = GenboreeAc.find_by_project_id(@project)
    if(@genboreeAc)
      @gbGroup = @genboreeAc.gbGroup.strip
      @gbHost = gbHost ? gbHost : @genboreeAc.gbHost.strip
      # Add standard field info to fieldMap IFF not provided
      fieldMap[:grp]  = @gbGroup unless(fieldMap[:grp].to_s =~ /\S/)
      fieldMap[:kb]   = @genboreeAc.gbKb.strip unless(fieldMap[:kb].to_s =~ /\S/)
      login, pass = getUserInfo(@gbHost)
      if(login and pass)
        # Make call, using fieldMap
        apiCaller = nil
        uri = nil
        if(login == :anon)
          apiCaller = BRL::REST::ApiCaller.new(@gbHost, rsrcPath)
          uri = apiCaller.makeFullApiUri(fieldMap, false)
        else
          apiCaller = BRL::REST::ApiCaller.new(@gbHost, rsrcPath, login, pass)
          uri = apiCaller.makeFullApiUri(fieldMap)
        end
        #$stderr.debugPuts(__FILE__, __method__, "STATUS", "About to get doc")
        if(payload.nil?)
          apiCaller.get( fieldMap )
        else
          apiCaller.get(fieldMap, payload.to_json)
        end
        #$stderr.debugPuts(__FILE__, __method__, "STATUS", "Got doc.")
        # Parse response
        parseOk = apiCaller.parseRespBody() rescue nil
        unless(apiCaller.succeeded? and parseOk)
          @respObj =
          {
            'data'    => nil,
            'status'  => ( parseOk ? apiCaller.apiStatusObj : { 'statusCode' => apiCaller.httpResponse.message, 'msg' => apiCaller.httpResponse.message } )
          }
          @httpResponse = @respObj['status']['msg']
        else
          if(jsonResp)

            @respObj = apiCaller.apiRespObj
            #$stderr.debugPuts(__FILE__, __method__, "STATUS", "@respObj:\n\n#{@respObj.inspect}")
            @httpResponse = @respObj['status']['msg'] ?  @respObj['status']['msg'] : ""
            @relatedJobIds = @respObj['status']['relatedJobIds']
          else
            @respObj = apiCaller.respBody
            @httpResponse = ""
          end
        end
        retVal[:respObj]  = @respObj
        retVal[:status]   = apiCaller.httpResponse.code.to_i
      else
        if(@currRmUser.member_of?(@project))
          @httpResponse = "ERROR: Current Redmine user does not seem to be registered with Genboree. Are they a locally-registered Redmine user? That is NOT supported, ONLY Genboree users are supported. Or perhaps the session has timed out."
          @gbGroup = @gbHost = ""
        else
          @httpResponse = "ERROR: Current user is not a member of the private Redmine project. "
          @gbGroup = @gbHost = ""
        end
      end
    else
      @httpResponse = "ERROR: Configuration missing for Actionability Curation app. Speak to a project admin to have it [re]set-up."
    end
    retVal[:msg] = @httpResponse
    return retVal
  end

  def apiPut(rsrcPath, payload, fieldMap={})
    # Maintain & return a hash of useful fields. We'll pass the needed onces (like :status, :location, etc) to Rails methods as needed.
    retVal = { :respObj => '', :status => 500 }
    @respObj = nil
    # Get typical generic info
    @genboreeAc = GenboreeAc.find_by_project_id(@project)
    if(@genboreeAc)
      @gbGroup = @genboreeAc.gbGroup.strip
      @gbHost = @genboreeAc.gbHost.strip
      # Add standard field info to fieldMap IFF not provided
      fieldMap[:grp]  = @gbGroup unless(fieldMap[:grp].to_s =~ /\S/)
      fieldMap[:kb]   = @genboreeAc.gbKb.strip unless(fieldMap[:kb].to_s =~ /\S/)
      login, pass = getUserInfo(@gbHost)
      if(login and pass)
        # Make call, using fieldMap
        #$stderr.puts "API PUT:\n  rsrcPath: #{rsrcPath.inspect}"
        #$stderr.puts "API PUT:\n  fieldMap: #{fieldMap.inspect}"
        apiCaller = BRL::REST::ApiCaller.new(@gbHost, rsrcPath, login, pass)
        apiCaller.put( fieldMap, payload )
        # Parse response
        parseOk = apiCaller.parseRespBody() rescue nil
        # Expose response
        #$stderr.debugPuts(__FILE__, __method__, "DEBUG", "API PUT SUCCESS? #{apiCaller.succeeded?.inspect} (hr: #{apiCaller.httpResponse}) ; ")
        unless(apiCaller.succeeded? and parseOk)
          @respObj =
          {
            'data'    => nil,
            'status'  => ( parseOk ? apiCaller.apiStatusObj : { 'statusCode' => apiCaller.httpResponse.message, 'msg' => apiCaller.httpResponse.message } )
          }
          @httpResponse = @respObj['status']['msg']
        else
          @respObj = apiCaller.apiRespObj
          @httpResponse = @respObj['status']['msg']
          @relatedJobIds = @respObj['status']['relatedJobIds']
        end
        #@respObj['data'] = {}
        retVal[:respObj]  = @respObj
        retVal[:status]   = ( ( apiCaller.httpResponse.code.to_i == 201 or apiCaller.httpResponse.code.to_i == 202 ) ? 200 : apiCaller.httpResponse.code.to_i ) # 201 causes the respond_to method to slow down considerably
      else
        @httpResponse = "ERROR: Current Redmine user does not seem to be registered with Genboree. Are they a locally-registered Redmine user? That is NOT supported, ONLY Genboree users are supported. Or perhaps the session has timed out."
        @gbGroup = @gbHost = ""
      end
    else
      @httpResponse = "ERROR: Configuration missing for Actionability Curation app. Speak to a project admin to have it [re]set-up."
    end
    retVal[:msg] = @httpResponse
    return retVal
  end

  def apiDelete(rsrcPath, fieldMap={})
    # Maintain & return a hash of useful fields. We'll pass the needed onces (like :status, :location, etc) to Rails methods as needed.
    retVal = { :respObj => '', :status => 500 }
    @respObj = nil
    # Get typical generic info
    @project = Project.find(params['project_id'])
    @genboreeAc = GenboreeAc.find_by_project_id(@project)
    if(@genboreeAc)
      @gbGroup = @genboreeAc.gbGroup.strip
      @gbHost = @genboreeAc.gbHost.strip
      # Add standard field info to fieldMap IFF not provided
      fieldMap[:grp]  = @gbGroup unless(fieldMap[:grp].to_s =~ /\S/)
      fieldMap[:kb]   = @genboreeAc.gbKb.strip unless(fieldMap[:kb].to_s =~ /\S/)
      login, pass = getUserInfo(@gbHost)
      if(login and pass)
        # Make call, using fieldMap
        #$stderr.puts "API DELETE:\n  rsrcPath: #{rsrcPath.inspect}"
        #$stderr.puts "API DELETE:\n  fieldMap: #{fieldMap.inspect}"
        apiCaller = BRL::REST::ApiCaller.new(@gbHost, rsrcPath, login, pass)
        apiCaller.delete( fieldMap )
        # Parse response
        parseOk = apiCaller.parseRespBody() rescue nil
        # Expose response
        #$stderr.debugPuts(__FILE__, __method__, "DEBUG", "API DELETE SUCCESS? #{apiCaller.succeeded?.inspect} (hr: #{apiCaller.httpResponse}) ; resp body:\n\n#{apiCaller.respBody}")
        unless(apiCaller.succeeded? and parseOk)
          @respObj =
          {
            'data'    => nil,
            'status'  => ( parseOk ? apiCaller.apiStatusObj : { 'statusCode' => apiCaller.httpResponse.message, 'msg' => apiCaller.httpResponse.message } )
          }
          @httpResponse = @respObj['status']['msg']
        else
          @respObj = apiCaller.apiRespObj
          #@respObj['data'] = {}
          @httpResponse = @respObj['status']['msg']
        end
        retVal[:respObj]  = @respObj
        retVal[:status]   = apiCaller.httpResponse.code.to_i
      else
        @httpResponse = "ERROR: Current Redmine user does not seem to be registered with Genboree. Are they a locally-registered Redmine user? That is NOT supported, ONLY Genboree users are supported. Or perhaps the session has timed out."
        @gbGroup = @gbHost = ""
      end
    else
      @httpResponse = "ERROR: Configuration missing for Actionability Curation app. Speak to a project admin to have it [re]set-up."
    end
    retVal[:msg] = @httpResponse
    return retVal
  end
  
  def getApiCaller(rsrcPath, fieldMap)
    retVal = nil
    # Get typical generic info
    @project = Project.find(params['project_id'])
    @genboreeAc = GenboreeAc.find_by_project_id(@project)
    if(@genboreeAc)
      @gbGroup = @genboreeAc.gbGroup.strip
      @gbHost = @genboreeAc.gbHost.strip
      # Add standard field info to fieldMap IFF not provided
      fieldMap[:grp]  = @gbGroup unless(fieldMap[:grp].to_s =~ /\S/)
      fieldMap[:kb]   = @genboreeAc.gbKb.strip unless(fieldMap[:kb].to_s =~ /\S/)
      login, pass = getUserInfo(@gbHost)
      if(login and pass)
        retVal = BRL::REST::ApiCaller.new(@gbHost, rsrcPath, login, pass)
      end
    end
    return [retVal, fieldMap]
  end


end
