module GenboreeAcAsyncHelper

  # Get the full Reference documents for all the References mentioned in the Actionability doc @kbDoc@;
  #   do so in non-blocking manner, calling dev callback with the array of Reference @KbDoc@s.
  # @note You should have already used the @genboreeAcSettings@ before_filter before using this method,
  #   and thus @gbHost, @gbGroup, @gbKb are all populated.
  # @param [BRL::Genboree::KB::KbDoc] kbDoc The Actionability document which may refer to 1+ refs.
  # @param [String] collName The name of the References collection where references can be found.
  # @param [Hash] opts (OPTIONAL) Hash of extra options/toggles. Currently just supports @:replaceWithNums@
  #   which indicates that the funny Reference DocIDs in the @kbDoc@ should be replaced with nice integers,
  #   suitable for making numbered-bibliography. Default is true.
  # @yieldparam [Array<KbDoc>,Exception,nil] refDocs Your code block will be called with the Array of
  #   Reference @KbDoc@s as an argument. You should consult @@lastApiReqErr@ and @@lastApiReqErrText@
  #   to see if there was an error; the @refDocs@ argument will be empty in these error cases.
  def getDocRefsAsync(kbDoc, collName, opts={ :replaceWithNums => true}, &callback)
    # Trim/compact the doc to get rid of "empty" properties
    refIds = extractReferenceIDs(kbDoc)
    refDocs = []
    if(refIds and !refIds.empty?)
      # Arrange to get full doc for all mentioned References in non-blocking way.
      uniqRefIds = refIds.uniq
      $stderr.debugPuts(__FILE__, __method__, "STATUS", "The doc #{kbDoc.getRootPropVal().inspect} has #{refIds.size} reference mentions ; there are #{uniqRefIds.inspect.size} unique reference docs.")
      initLastApiErrVars()
      @lastApiReq = GbApi::JsonAsyncApiRequester.new(env, @gbHost, @project) unless(@lastApiReq)
      rsrcPath = '/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?matchProp=Reference&matchMode=exact&detailed=true&matchValues={vals}'
      fieldMap  = { :grp => @gbGroup, :kb => @gbKb, :coll => collName, :vals => uniqRefIds }
      @lastApiReq.bodyFinish {
        #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "++++++ DOC ASYNC - GET REFS DETAILS: in bodyFinish callback")
        begin
          if(@lastApiReq.apiDataObj and @lastApiReq.respStatus < 400 and !@lastApiReq.apiDataObj.is_a?(Exception))
            rawRefDocs = @lastApiReq.apiDataObj
            refDocs = rawRefDocs.map { |refDoc| BRL::Genboree::KB::KbDoc.new( refDoc ) }
            #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "++++++ DOC ASYNC - GET REFS DETAILS: SUCCESS - have ref KbDocs; resp was #{@lastApiReq.respStatus.inspect} with #{@lastApiReq.rawRespBody.size} byte payload")
            # Replace reference values in kbDoc if asked.
            if(opts[:replaceWithNums] or opts[:replaceRefLinksWith] == :nums)
              replaceRefLinks(kbDoc, refIds, refDocs, :nums)
            elsif(opts[:replaceRefLinksWith] == :docIds)
              replaceRefLinks(kbDoc, refIds, refDocs, :docIds)
            end
          else
            refDocs = []
            @lastApiReqErrText = "ERROR: Could not retrieve references mentioned in Actionability doc with ID #{docId.inspect}."
            $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "++++++ DOC ASYNC: FAILED - #{@lastApiReqErrText.inspect}. Response status code was: #{@lastApiReq.respStatus.inspect rescue 'N/A'}. Here is resp payload:\n\n#{kbDoc.inspect}\n\n")
          end
        rescue Exception => err
          refDocs = []
          @lastApiReqErr = err
          @lastApiReqErrText = "ERROR: could not retrieve references mentioned in document due to a bug."
          $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{@lastApiReqErrText.inspect} Response status code was: #{@lastApiReq.respStatus.inspect rescue 'N/A'}\n    Error class: #{err.class}\n    Error message: #{err.message}\n    Error trace:\n#{err.backtrace.join("\n")}")
        ensure
          # Call dev's callback with the KbDoc they wanted
          callback.call( refDocs )
        end
      }
      @lastApiReq.get(rsrcPath, fieldMap)
      # NO CODE HERE. Async.
    else
      # No references? Nothing to do.
      #$stderr.debugPuts(__FILE__, __method__, "WARNING", "The doc #{kbDoc.getRootPropVal().inspect} has NO reference mentions ??")
      callback.call( refDocs )
    end
    # NO CODE HERE. Async.
  end

  # Convenience method. A number of controller-actions which have Views set appropriate
  #   instance variables which are used by the View to render the page. This method
  #   can be used to arrange for appropriate rendering of the View to the client--even
  #   if some early sanity checks meant NO non-blocking/async api requests were made (thus apiReq is empty), this
  #   method will render normally or via the async-compatible renderToClient() method.
  # @param [Symbol] view The View (usually matches the Controller Action), as a Symbol. e.g. @:show@
  #   or @:index@ or @:update@ are common/standard.
  # @param [GbApi::SimpleAsyncApiRequester, nil] apiReq IFF async/non-blocking http requests were initiated and thus
  #   Thin knows this is an async/deferred response then this will be a non-nil {GbApi::SimpleAsyncApiRequester}
  #   instance used for the request (defaults to @@lastApiReq@ since likely you're using the {GenboreeAcAsyncHelper}
  #   mixin methods). If async request handling was never initiated--probably due to up-front sanity checks--then
  #   there is no such instance and thus @nil@ is passed. This will result in normal (non-async) rendering, probably
  #   of an error display.
  def renderPage( view, apiReq=@lastApiReq )
    if(apiReq)
      if(!@lastApiReqErrText.nil? or !@viewMsg.nil?) # some little error message we want user to see (presumably logged)
        apiReq.renderToClient(self, view)
      else # can render full doc
        apiReq.renderToClient(self, view, apiReq.respStatus)
      end
      # NO CODE HERE. Async.
    else # non-async flow
      # @kbDoc will be nil, since we never went through the apiReq, nor did we do async handling of this request
      render(view, { :content_type => "text/html", :status => "OK" })
    end
  end

  def initLastApiErrVars()
    @lastApiReqErr = @lastApiReqErrText = nil
  end
end