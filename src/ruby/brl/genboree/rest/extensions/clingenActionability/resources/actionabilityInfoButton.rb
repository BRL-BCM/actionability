#!/usr/bin/env ruby
require 'cgi'
require 'brl/util/util'
require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/kb/producers/abstractTemplateProducer'
require 'brl/genboree/rest/helpers'
require 'brl/genboree/rest/extensions/helpers'
require 'brl/genboree/rest/wrapperApiCaller'
require 'brl/genboree/rest/resources/genboreeResource'
require 'brl/genboree/rest/extensions/clingenActionability/data/actionabilityLookupDocEntity'

module BRL ; module REST ; module Extensions ; module ClingenActionability ; module Resources

  # Actionability Info Button
  # - Lookup actionability docs based on OMIM id or HGNC and return ATOM feed of matches
  # - For info-button integration
  #
  # Data representation classes used:

  class ActionabilityInfoButton < BRL::REST::Resources::GenboreeResource
    include BRL::Genboree::REST::Extensions::Helpers
    # INTERFACE CONSTANTS

    # @return [Hash{Symbol=>Object}] Map of what http methods this resource supports ( @{ :get => true, :put => false }@, etc } ).
    HTTP_METHODS     = { :get => true }
    API_EXT_CATEGORY = 'clingenActionability'
    RSRC_TYPE        = 'actionabilityInfoButton'

    # Class specific constants
    MODEL_GB_RSRC_PATH = '/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/model?format=json_pretty'
    DOCS_GB_RSRC_PATH = '/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?matchProps={props}&matchValues={vals}&matchLogicOp=and&matchMode=exact&detailed=true&format=json_pretty'
    VERS_GB_RSRC_PATH = '/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs/ver/HEAD?docIDs={docs}&detailed=no'
    PROPS             = { 'HGNC' => 'ActionabilityDocID.Genes.Gene.HGNCId', 'OMIM' => 'ActionabilityDocID.Syndrome.OmimIDs.OmimID' }
    KBDOC_OPTS = { :nilGetOnPathError => true }

    FEED_CORE_MODEL = {
      'name' => 'feed', 'required' => true, 'domain' => 'string', 'index' => true, 'unique' => true, 'identifier' => true, 'properties' => [
        { 'name' => 'xmlBase', 'required' => true, 'domain' => 'string' },
        { 'name' => 'title', 'required' => true, 'domain' => 'string' },
        { 'name' => 'subtitle', 'required' => true, 'domain' => 'string' },
        { 'name' => 'author', 'required' => true, 'domain' => '[valueless]', 'fixed' => true, 'properties' => [
          { 'name' => 'name', 'required' => true, 'domain' => 'string' },
          { 'name' => 'uri', 'required' => true, 'domain' => 'string' }
        ] },
        { 'name' => 'updated', 'required' => true, 'domain' => 'string' },
        { 'name' => 'category', 'required' => true, 'domain' => '[valueless]', 'fixed' => true, 'properties' => [
          { 'name' => 'termC', 'required' => true, 'domain' => 'string' },
          { 'name' => 'termCS', 'required' => true, 'domain' => 'string' }
        ] },
        { 'name' => 'actionabilityDocs', 'required' => true, 'domain' => '[valueless]', 'fixed' => true, 'items' => [ ] }
      ]
    }

    # @api RestAPI INTERFACE. CLEANUP: Inheriting classes should also implement any specific
    #   cleanup that might save memory and aid GC. Their version should call {#super}
    #   so any parent {#cleanup} will be done also.
    # @return [nil]
    def cleanup()
      super()
    end

    # @api RestAPI INTERFACE. return a {Regexp} that will match a correctly formed URI for this service
    #   The pattern will be applied against the URI's _path_.
    # @returns [Regexp]
    def self.pattern()
      apiExtConf = self.loadConf(self::API_EXT_CATEGORY, self::RSRC_TYPE)
      rsrcPathBase = (
      (apiExtConf['rsrc'] and apiExtConf['rsrc']['pathBase']) ?
        apiExtConf['rsrc']['pathBase'].strip :
        "/REST-ext/#{CGI.escape(self::API_EXT_CATEGORY)}/#{CGI.escape(self::RSRC_TYPE)}"
      )
      rsrcPathBase.chomp!('/')
      regexp =  %r{^#{Regexp.escape(rsrcPathBase)}/(HGNC|OMIM)/([^/\?]+)$}
      #$stderr.debugPuts(__FILE__, __method__, "DEBUG", "API Ext Class will match: #{regexp.source}")
      return regexp
    end

    # @api RestAPI return integer from 1 to 10 that indicates whether the regexp/service is
    #   highly specific and should be examined early on, or whether it is more generic and
    #   other services should be matched for first.
    # @return [Fixnum] The priority, from 1 t o 10.
    def self.priority()
      return 8
    end

    # Perform common set up needed by all requests. Extract needed information,
    #   set up access to parent group/database/etc resource info, etc.
    # @return [Symbol] a {Symbol} corresponding to a standard HTTP response code [official English text, not the number]
    #   indicating success/ok (@:OK@), some other kind of success, or some kind of failure.
    def initOperation()
      initStatus = super()
      # Load this extension's config
      @apiExtConf = self.class.loadConf(self.class::API_EXT_CATEGORY, self.class::RSRC_TYPE)
      #$stderr.debugPuts(__FILE__, __method__, "DEBUG", ">>> @apiExtConf:\n\n#{@apiExtConf.inspect}\n\n")
      if(initStatus == :OK and @apiExtConf)
        @gbRsrcTmpl   = DOCS_GB_RSRC_PATH.dup
        @versRsrcTmpl = VERS_GB_RSRC_PATH.dup
        @acGbHost     = @apiExtConf['records']['host']
        @groupName  = @apiExtConf['records']['grp']
        @kbName     = @apiExtConf['records']['kb']
        @kbColl     = @apiExtConf['records']['coll']
        @acLogin      = @apiExtConf['records']['login']
        @templateDir = self.class.templateDir( self.class::API_EXT_CATEGORY, self.class::RSRC_TYPE, @apiExtConf )
        # Get tag name and value to search for
        @tagName      = Rack::Utils.unescape(@uriMatchData[1].to_s.strip).upcase
        @tagValue     = Rack::Utils.unescape(@uriMatchData[2].to_s.strip)
        # - For HGNC tag, add prefix to value if not already present
        @tagValue = "HGNC:#{@tagValue}" if(@tagName =~ /HGNC/ and @tagValue !~ /^HGNC:/)
        # Default format for this extension is json_pretty
        @responseFormat = :JSON_PRETTY unless(@nvPairs['format'] or @nvPairs['responseFormat'])
        # Get the userId of the login who will do any records access for us
        @acUserId = userIdForLogin(@acLogin)
        # $stderr.debugPuts(__FILE__, __method__, 'DEBUG', ">>> @actionabilityUserId for #{@acLogin.inspect}: #{@acUserId.inspect}")
      elsif(@apiExtConf.nil?)
        initStatus = @statusName = :'Internal Server Error'
        @statusMsg = "FATAL ERROR: System failed to locate the required API extension config file for #{self.class::API_EXT_CATEGORY.inspect} - #{self.class::RSRC_TYPE.inspect}. System is misconfigured, please contact an administrator to help resolve this issue."
      #else # initStatus != :OK, super() should have already set @statusX vars
      end
      return initStatus
    end

    # Process a GET operation on this resource.
    # @return [Rack::Response] instance configured and containing correct status code, message, and wrapped data;
    #   or containing correct error information.
    def get()
      initStatus = initOperation()
      # $stderr.debugPuts(__FILE__, __method__, 'DEBUG', ">>> Init status: #{initStatus.inspect} ; @groupAccessStr: #{@groupAccessStr.inspect} ; @groupName: #{@groupName.inspect} ; @kbName: #{@kbName.inspect} ; @kbColl: #{@kbColl.inspect} ; @reqMethod: #{@reqMethod.inspect} ; @dbu:\n\n#{@dbu}\n\n")
      if(initStatus == :OK)
        initStatus = initGroupAndKb()
        # $stderr.debugPuts(__FILE__, __method__, 'DEBUG', ">>> init grp/kb Status: #{initStatus.inspect} ; @groupAccessStr: #{@groupAccessStr.inspect}")
        # All accesses to this service are non-login; that's the point of this service.
        # Even if they authenticated, access will be "public" mode.
        # * While this API is public, access to the underlying grp/kb from the conf file may not be.
        # * Therefore we are employing a shim user based on info from the conf file; the shim userId is in @actionabilityUserId
        @groupAccessStr = 'p'
        # Would need to do this conf stuff first and then init...
        if(READ_ALLOWED_ROLES[@groupAccessStr])
          # ApiCaller to search for matchProps based search
          apiCaller = BRL::Genboree::REST::WrapperApiCaller.new(@acGbHost, @gbRsrcTmpl, @acUserId)
          apiCaller.initInternalRequest(@rackEnv, @genbConf.machineNameAlias) if(@rackEnv)
          apiCaller.get( {
                           :grp  => @groupName,
                           :kb   => @kbName,
                           :coll => @kbColl,
                           :props  => PROPS[@tagName],
                           :vals   => [ @tagValue ]
                         })
          #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', ">>> doc search apiCaller success? #{apiCaller.succeeded?} ; http code: #{apiCaller.httpResponse.code.inspect}")
          if(apiCaller.succeeded?) # if(apiCaller.success?)
            apiCaller.parseRespBody()
            acDocs = apiCaller.apiDataObj
            if(apiCaller.apiDataObj.is_a?(Array))
              if(apiCaller.apiDataObj.size < 1)
                matchingDocs = []
              else # no matches, return empty feed
                matchingDocs = apiCaller.apiDataObj
              end

              # Wrap all the resp docs as KbDocs so can work with them sensibly
              matchingDocs.map { |doc| kbDoc = BRL::Genboree::KB::KbDoc.new(doc) }

                # Construct model of feed doc
              feedModel = buildFeedModel()

              # Set up a fake KB doc with feed info + all relevant actionability docs, to give to template
              feedKbDoc = BRL::Genboree::KB::KbDoc.new( {} )
              feedKbDoc.setPropVal( 'feed', "#{@tagName}:#{@tagValue}")
              # - Add static info from config to this fake doc
              staticInfo = @apiExtConf['template']['staticInfo']
              staticInfo.keys.sort.each { |propPath|
                feedKbDoc.setPropVal( propPath, staticInfo[propPath] )
              }
              # - Set the feed timestamp and category info
              feedKbDoc.setPropVal( 'feed.updated', Time.now.utc.iso8601 )
              feedKbDoc.setPropVal( 'feed.category', '' )
              feedKbDoc.setPropVal( 'feed.category.termC', @tagName )
              feedKbDoc.setPropVal( 'feed.category.termCS', @apiExtConf['template']['categories'][@tagName]['term'] )
              # - Add the list of matching actionability docs
              feedKbDoc.setPropItems( 'feed.actionabilityDocs', acDocs )

              # Next, must go get the version records for these docs. We need that in order to construct the correct payload.
              # - Rather than add this somehow into feed doc, we'll just pass in a map of docId => UTC timestamp within
              #   the template options, then it's available to templates to examine.
              if(matchingDocs.empty?)
                versionDocs = {}
                docModTimes = {}
              else
                versionDocs = getVersionDocs(matchingDocs)
                docModTimes = extractDocModTimes(versionDocs)
              end

              # Options for template producer
              opts = { :twoCharNewline => true, :docModTimes => docModTimes, :templateDir => @templateDir }
              # Create template producer

              xmlProducer =  BRL::Genboree::KB::Producers::AbstractTemplateProducer.new( feedModel, feedKbDoc, opts )
              # Render doc
              xml = xmlProducer.render(:feedXml)
              #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "feedModel:\n\n#{feedModel.inspect}\n\n")
              #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "feedKbDoc:\n\n#{feedKbDoc.inspect}\n\n")
              # 4. Should set content-type and such
              @statusName = :OK
              @resp.body = xml
              @resp.status = HTTP_STATUS_NAMES[@statusName]
              @resp['Content-Type'] = BRL::Genboree::REST::Data::AbstractEntity::FORMATS2CONTENT_TYPE[:XML]
              @resp['Content-Length'] = xml.size.to_s rescue 0
            else # Not an Array response, how odd
              @statusName = :'Internal Server Error'
              @statusMsg = "FATAL ERROR: Querying for Actionability docs for #{@tagName.inspect} ID of #{@tagValue.inspect} returned an unexpected and unprocessable payload. Please contanct an Administrator who can coordinate an investigation."
              $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{@statusName.inspect} - #{@statusMsg} ; apiCaller.respBody:\n\n#{apiCaller.respBody.inspect rescue 'N/A'}\n\n")
            end
          else # API Error...404 is UNexpected, because it's about the the grp/kb/coll
            # Attempt to parse response
            parsedResp = apiCaller.parseRespBody() rescue nil
            respStatus = (parsedResp ? apiCaller.apiStatusObj['statusCode'] : 'N/A')
            respMsg = (parsedResp ? apiCaller.apiStatusObj['msg'] : 'N/A')
            @statusName = :'Internal Server Error'
            @statusMsg = "ERROR: This service and/or the underlying resources are not configured correctly and the file records in general cannot be searched. Specific internal code was: #{respStatus.inspect} ; internal message was: #{respMsg.inspect}"
            $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{@statusName.inspect} - #{@statusMsg}")
          end
        else
          @statusName = :Forbidden
          @statusMsg = 'FORBIDDEN: You do not have sufficient permissions to perform this operation.'
        end
      end
      # If something wasn't right, represent as error
      @resp = representError() if(@statusName != :OK and @statusName != :Found)
      return @resp
    end # get()

    # ----------------------------------------------------------------
    # INTERNAL HELPERS
    # ----------------------------------------------------------------
    private

    def buildFeedModel()
      retVal = nil
      rsrcTmpl = MODEL_GB_RSRC_PATH.dup
      apiCaller = BRL::Genboree::REST::WrapperApiCaller.new(@acGbHost, rsrcTmpl, @acUserId)
      apiCaller.initInternalRequest(@rackEnv, @genbConf.machineNameAlias) if(@rackEnv)
      apiCaller.get( {
                         :grp  => @groupName,
                         :kb   => @kbName,
                         :coll => @kbColl
      } )
      if(apiCaller.succeeded?)
        apiCaller.parseRespBody
        # Build actual feed model: core + actual actionability doc model
        # - core:
        feedModel = FEED_CORE_MODEL.deep_clone
        feedModelHelper = BRL::Genboree::KB::Helpers::ModelsHelper.new(feedModel)
        acDocsPropDef = feedModelHelper.findPropDef('feed.actionabilityDocs', feedModel)
        # - integrate actual actionability doc model (we will have array of these in the feed model)
        acDocsPropDef['items'] << apiCaller.apiDataObj
        retVal = feedModel
      else
        retVal = nil
        @statusName = :'Not Found'
        @statusMsg = "NOT_FOUND: No Actionability document model for #{@kbColl.inspect} document collection. Is system correctly configured and does #{@acUserId.inspect} have sufficient access?"
      end
      return retVal
    end

    def extractDocModTimes(versionDocs)
      docModTimes = {}
      versionDocs.each_key { |docId|
        verInfoDoc = versionDocs[docId]
        # Get version time, as UTC ISO8601 string
        verTime = verInfoDoc.getPropVal( 'versionNum.timestamp' )
        if(verTime.is_a?(String) and !verTime.empty?)
          verTime = Time.parse(verTime) rescue Time.at(-1)
        else
          verTime = Time.at(-1)
        end
        docModTimes[docId] = verTime
      }
      return docModTimes
    end

    def getVersionDocs(docArray)
      retVal = {}
      # @todo What if number of kbDocs is HUGE? Long URL! Best: make sure can provide _payload_ of docIDs for following request
      docIds = docArray.reduce([]) { |array, doc| kbDoc = BRL::Genboree::KB::KbDoc.new(doc) ; array << kbDoc.getRootPropVal() ; array }
      #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', ">>> Need version recs for these #{docIds.size} (param size: #{docArray.size}) docs:\n\n#{docIds.join("\n")}\n\n")

      apiCaller = BRL::Genboree::REST::WrapperApiCaller.new(@acGbHost, @versRsrcTmpl, @acUserId)
      apiCaller.initInternalRequest(@rackEnv, @genbConf.machineNameAlias) if(@rackEnv)
      apiCaller.get( {
                       :grp  => @groupName,
                       :kb   => @kbName,
                       :coll => @kbColl,
                       :docs => docIds
                     })
      $stderr.debugPuts(__FILE__, __method__, 'DEBUG', ">>> version recs apiCaller success? #{apiCaller.succeeded?} ; http code: #{apiCaller.httpResponse.code.inspect}")
      if(apiCaller.succeeded?) # if(apiCaller.success?)
        apiCaller.parseRespBody()
        if(apiCaller.apiDataObj.is_a?(Array))
          if(apiCaller.apiDataObj.size != docArray.size)
            @statusName = :'Internal Server Error'
            @statusMsg = "FATAL ERROR: When retrieving history records for the #{docArray.size} matching Actionability docs, only received back history records for #{apiCaller.apiDataObj.size} docs!"
            $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{@statusName.inspect} - #{@statusMsg} ; apiCaller.respBody length: #{apiCaller.respBody.size rescue 'N/A'}\n\n")
          else
            apiCaller.apiDataObj.each { |verRec|
              docId = verRec.keys.first
              verDoc = BRL::Genboree::KB::KbDoc.new(verRec[docId]['data'], KBDOC_OPTS)
              retVal[docId] = verDoc
            }
            # $stderr.debugPuts(__FILE__, __method__, 'DEBUG', ">>> Now have map of #{retVal.size} docIDs to kbVersion docs. For example: #{retVal.keys.first.inspect} maps to:\n\n#{JSON.pretty_generate(retVal[retVal.keys.first])}\n\n")
          end
        else # Not an Array response, how odd
          @statusName = :'Internal Server Error'
          @statusMsg = "FATAL ERROR: Retrieving history records for the #{docArray.size} for matching Actionability docs did not return an array of history records. Please contanct an Administrator who can coordinate an investigation."
          $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{@statusName.inspect} - #{@statusMsg} ; apiCaller.respBody:\n\n#{apiCaller.respBody.inspect rescue 'N/A'}\n\n")
        end
      else # API Error...404 is UNexpected, because it's about the the grp/kb/coll
        # Attempt to parse response
        parsedResp = apiCaller.parseRespBody() rescue nil
        respStatus = (parsedResp ? apiCaller.apiStatusObj['statusCode'] : 'N/A')
        respMsg = (parsedResp ? apiCaller.apiStatusObj['msg'] : 'N/A')
        @statusName = :'Internal Server Error'
        @statusMsg = "ERROR: This service and/or the underlying resources are not configured correctly and the history records in general cannot be retrieved. Specific internal code was: #{respStatus.inspect} ; internal message was: #{respMsg.inspect}"
        $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{@statusName.inspect} - #{@statusMsg}")
      end
      return retVal
    end
  end # class ActionabilityDoc < BRL::REST::Resources::GenboreeResource
end ; end ; end ; end ; end # module BRL ; module REST ; module Extensions ; module ClingenActionability ; module Resources
