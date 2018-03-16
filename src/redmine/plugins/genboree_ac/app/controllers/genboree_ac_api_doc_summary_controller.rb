class GenboreeAcApiDocSummaryController < ApplicationController
  ACTION2TEMPLATE = {
    :summary  => :docSummaryBase,
    :genes    => :docSummaryGene,
    :omims    => :docSummaryOmim,
    :consensus_scores => :docSummaryScoresOutcome
  }
  FORMAT2HEADERS = {
    'json'    => { 'Content-Type' => 'application/json' },
    'json-ld' => { 'Content-Type' => 'application/json' }
  }

  include GenboreeAcApiDocSummaryHelper

  unloadable

  respond_to :json

  before_filter :find_project, :authorize, :find_settings
  before_filter :docIdentifier
  before_filter { |ctrlr|
    $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "@settingsRec.requireHttpsForApi: #{@settingsRec.requireHttpsForApi.inspect} ; api_request? #{api_request?} ; accept_api_auth? #{accept_api_auth?}")
    if( @settingsRec.requireHttpsForApi and api_request? and Setting.rest_api_enabled? and accept_api_auth? )
      $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Looks like API request being done and project requires https for such. Reject unless https.")
      reject_unless_client_request_https
    else
      true
    end
  }

  #before_filter :authorize_via_perms_only

  # @todo Consider improving Redmine's api_request? implementation to not only look for format==xml or format==json
  #   (which require the format be explicitly present due to nature of route, such as doc.json, or require explicit query parameter 'format=X' in URI)
  #   but could also consult the parameters and look for something the route's :defaults => {} put in place such as
  #   :default => { :apiRoute => true }. Then would not HAVE to supply format info in order to activate API authorization via api key.
  accept_api_auth :full, :dispatcher, :all_scores

  def full()
  end

  def all_scores()
  end

  def dispatcher()
    $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "api_request? #{api_request? rescue 'N/A'} ; format: #{format.inspect rescue 'n/a'} ; params:\n\n#{params.inspect}\n\nsettingsRec:\n\n#{@settingsRec.inspect}\n\n")
    @component = params[:component]
    setup()
    renderDoc() # async
    # Nothing after this, async ops are being arranged
  end

  # ----------------------------------------------------------------
  # Common helpers
  # ----------------------------------------------------------------

  def setup()
    @docId = params['docId']
    @format = (params['format'] or 'json')
    @flavor = (params['flavor'] or 'api')
    @component = params['component']
    @acDocVersion = params['version']
    @acDocVersion = ( @acDocVersion.blank? ? nil : @acDocVersion.to_i )
    @templateGroup = "#{@flavor}-#{@format}"
    @template = ACTION2TEMPLATE[@component]
    @kbDoc = @viewMsg = nil
    # Project-plugin settings
    @gbHost = @settingsRec.gbHost
    @gbGroup = @settingsRec.gbGroup
    @gbKb = @settingsRec.gbKb
    @acCurationColl = @settingsRec.actionabilityColl
    @producerOpts = { }
    #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Setup complete. API component #{@component.inspect} ; templateGroup: #{@templateGroup.inspect} ; template: #{@template.inspect} ; GB info: #{@gbHost.inspect} -> #{@gbGroup.inspect} -> #{@gbKb.inspect} -> #{@acCurationColl.inspect} -> doc: #{@docId.inspect}")
  end

  def renderDoc()
    getModelAsync( @acCurationColl ) { |model|
      # Now that we have the models, async get and process the doc
      if( model and !model.is_a?( Exception ) )
        # Get the AC doc
        getDocAsync( @docId, @acCurationColl, { :docVersion => @acDocVersion } ) { |kbDoc|
          if( kbDoc.is_a?(BRL::Genboree::KB::KbDoc) and @lastApiReqErrText.nil? )
            @kbDoc = kbDoc
          else
            @kbDoc = nil
            @viewMsg = "ERROR: #{@lastApiReqErrText.to_s.strip.chomp('.') + '.'}"
          end

          if( @kbDoc and @viewMsg.nil? )
            # @todo Enable proper API rendering for non-CURR versions (like reports, uses TemplateSets) when
            #   retrieval of current version number of a doc is MUCH FASTER. API call currently very slow (kbDocVersion.rb)

            ## Need to know current version of @docIdentifier, no matter what..
            #getDocCurrVersionNumAsync( @docId, @acCurationColl) { |headVersionNum|
              #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Have head version num: #{headVersionNum.inspect}")
              #if( headVersionNum.is_a?(Numeric) )
              #  @headVersionNum = headVersionNum
              #  if( @acDocVersion )
              #    @viewingHeadVersion = ( @acDocVersion == @headVersionNum )
              #  else # no version specified in URI
              #    @acDocVersion = @headVersionNum
                  @viewingHeadVersion = true
              #  end
              #else
              #  @kbDoc = nil
              #  @viewMsg = "ERROR: #{@lastApiReqErrText.to_s.strip.chomp('.') + '.'}"
              #end
              #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Are we rendering the head version of #{@docId.inspect}? #{@viewingHeadVersion.inspect}")

              if( @kbDoc and @viewMsg.nil? )
                # Ensure version context is available to templates (if needed like for reports; currently is not)
                @producerOpts[:viewingHeadVersion]  = @viewingHeadVersion
                @producerOpts[:viewAcDocVersion]    = @acDocVersion
                @producerOpts[:headAcDocVersion]    = @headVersionNum
                # Producer settings suitable for templates that make JSON
                @producerOpts[:skipValidation]      = true
                @producerOpts[:skipVariabilization] = true # big speed up
                @producerOpts[:relaxedRootValidation]   = true
                @producerOpts[:supressNewlineAfterItem] = true
                @producerOpts[:itemPostfix]         = '' # supress default extra space after items (invisible in HTML, but not in JSON)
                @producerOpts[:context]             = {}
                @producerOpts[:context][:requestUrl]          = request.url
                @producerOpts[:context][:releaseKbRsrcPath]   = @settingsRec.gbReleaseKbRsrcPath
                @producerOpts[:context][:releaseRptBase]      = @settingsRec.releaseKbBaseUrl
                @producerOpts[:context][:actionabilityColl]   = @settingsRec.actionabilityColl

                # Get TemplateSets info doc, determine appropriate TemplateSet, fill template set related instance variables
                #   so View has access, then render view of this verison of the doc using the correct template set (async)
                loadTemplateSetAndRender( env, @acDocVersion ) {
                  #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Here is auto-determined template set for #{@docId.inspect} @ #{@acDocVersion.inspect}: #{@templateSet.inspect}")
                  if( @kbDoc and @viewMsg.nil? )
                    begin
                      # This method determines the template-set based on the doc version argument, and makes @templateSet available.
                      # Thus, can now build the path to the templates that the Producer will employ:
                      @producerOpts[:templateDir] = templateGroupDir( @templateGroup, @templateSet )

                      # Can instantiate an AbstractTemplateProducer now. May have some very specific opts depending
                      #   on coponent, but largely common to all.
                      docProducer = BRL::Genboree::KB::Producers::AbstractTemplateProducer.new( model, @kbDoc, @producerOpts )
                      case @component
                        when :summary
                          renderFromRoot( :docSummaryBase, docProducer )
                        when :genes
                          renderItems( 'ActionabilityDocID.Genes', :docSummaryGene, docProducer )
                        when :omims
                          renderItems( 'ActionabilityDocID.Syndrome.OmimIDs', :docSummaryOmim, docProducer )
                        when :consensus_scores
                          renderItems( 'ActionabilityDocID.Score.Final Scores.Outcomes', :docSummaryScoresOutcome, docProducer )
                        else
                          renderError()
                      end
                    rescue => err
                      @viewMsg = "ERROR: Failed to generate the response payload due to an error. Error type: #{err.class}. Error messge: #{err.message}"
                      $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Exception raised while making Producer or calling specific render method. #{@viewMsg}. Trace:\n#{err.backtrace.join("\n")}")
                      renderError()
                    end
                  else # error, so @kbDoc cleared and/or @viewMsg set
                    $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Error while trying to determine appropriate template set, etc. #{@viewMsg}.")
                    renderError()
                  end
                }
              else # error, so @kbDoc cleared and/or @viewMsg set
                $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Error getting head version number for doc #{@docId.inspect}. #{@viewMsg}.")
                renderError()
              end
            #}
          else # error, so @kbDoc cleared and/or @viewMsg set
            $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Error getting doc contents. #{@viewMsg}.")
            renderError()
          end
        }
      else   # error, so @kbDoc cleared and/or @viewMsg set
        $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Error getting model for collection #{@acCurationColl.inspect}. #{@viewMsg}.")
        @kbDoc = nil
        @viewMsg = 'ERROR: Could not retrieve document metadata from underlying Genboree storage. Possibly you do not have permission within Genboree or there is a configuration problem; please speak to an Administrator to resolve this issue.'
        logMsg = @viewMsg
        if( model.is_a?(Exception) )
          err = model
          logMsg = "#{@viewMsg}\n        Error class: #{err.class}\n        Error message: #{err.message}\n        Error trace:\n#{err.backtrace.join("\n") }"
        end
        $stderr.debugPuts(__FILE__, __method__, "GENBOREE AC", "#{logMsg}")
        renderError()
      end
    }
  end

  def renderFromRoot( template, docProducer )
    rendered = docProducer.render( template )
    headers = { 'Content-Length' => rendered.size.to_s }
    headers = FORMAT2HEADERS[@format].merge( headers )
    @lastApiReq.sendToClient( 200, headers, rendered )
  end

  def renderItems( itemListPath, template, docProducer )
    # Each sub-doc should be indented below top-level "[ ]" provider here
    docProducer.opts[:context][:lineIndent] = ( ' ' * 2 )
    # Render each  sub-doc within this in-line template.
    # * Put a comma and newline after each Gene sub-doc.
    rendered = docProducer.render( %Q^[\n  <!%= render_each( '#{itemListPath}', :#{template}, ",\n" ) %!>\n]^ )
    headers = { 'Content-Length' => rendered.size.to_s }
    headers = FORMAT2HEADERS[@format].merge( headers )
    @lastApiReq.sendToClient( 200, headers, rendered )
  end

  def renderError( status=500 )
    payload = { 'status' => BRL::REST::ApiCaller::HTTP_STATUS_CODES[status], 'error' => @viewMsg }
    payloadStr = JSON.pretty_generate( payload )
    headers = { 'Content-Length' => payloadStr.size.to_s }
    headers = FORMAT2HEADERS[@format].merge( headers )
    @lastApiReq.sendToClient( status, headers, payloadStr)
  end
end
