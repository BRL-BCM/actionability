class GenboreeAcUiStg2SummaryReportController < ApplicationController
  class GenboreeAcUiStg2SummaryReportControllerError < StandardError; end

  include GenboreeAcUiStg2SummaryReportHelper

  respond_to :json

  before_filter :find_project, :authorize
  before_filter :getKbMount, :docIdentifier
  before_filter :userPerms, :genboreeAcSettings

  unloadable

  layout 'ac_bootstrap_extensive_hdr_ftr'

  #before_filter :require_admin, :only => [ :create ]
  #
  ## ------------------------------------------------------------------
  ## Possibly helps with API support and certainly API-KEY type authentication.
  ## ------------------------------------------------------------------
  #skip_before_filter :check_if_login_required
  #skip_before_filter :verify_authenticity_token
  #
  #accept_api_auth :index, :create, :delete

  def show()
    @kbDoc = @viewMsg = nil
    @docModel = @refModel = nil

    if(@docIdentifier)
      # Get the models...need them for rendering.
      # First, get the doc model
      getModelAsync(@acCurationColl) { |docModel|
        @docModel = docModel
        $stderr.debugPuts(__FILE__, __method__, '++++++ DEBUG', "Getting doc model #{(docModel.is_a?(Hash) and @lastApiReqErrText.nil?) ? 'SUCCEEDED' : 'FAILED'}")
        # Now get ref model
        getModelAsync(@acRefColl) { |refModel|
          @refModel = refModel
          # Now that we have the models, async get and process the doc
          processDoc(@docModel)
        }
      }
      # NO CODE HERE! Async.
    else
      # No doc identifier. Can reply immediately with error message.
      @kbDoc = nil
      @viewMsg = "Missing doc identifier / bad url."
      renderPage(:show)
    end
  end

  def processDoc(docModel=@docModel, refModel=@refModel)
    if(docModel and !docModel.is_a?(Exception) and refModel and !refModel.is_a?(Exception))
      # Get AC doc from Genboree
      getDocAsync(@docIdentifier, @acCurationColl) { |kbDoc|
        @kbDoc = kbDoc
        if(@kbDoc.is_a?(BRL::Genboree::KB::KbDoc) and @lastApiReqErrText.nil?)
          @kbDoc = trimDoc(@kbDoc) if(@trim)
          # Extract reference properties (ALL, in order of appearance, including dups).
          #   This will discover the references mentioned in the actionability doc and then
          #   arrange to retrieve each reference's full document in a non-blocking (async) way.
          #getDocRefsAsync(@kbDoc, @acRefColl, :replaceWithNums=>true) { |refDocs|
          getDocRefsAsync(@kbDoc, @acRefColl, :replaceWithNums=>false, :replaceRefLinksWith=>:docIds) { |refDocs|
            @refDocs = refDocs
            unless(@refDocs.is_a?(Array) and @lastApiReqErrText.nil?)
              # Something went wrong
              @viewMsg = "#{@lastApiReqErrText} Error while trying to retrieve the reference details for each reference mentioned in the Actionability doc #{@docIdentifier.inspect}."
            end
            renderPage(:show)
          }
          # NO CODE HERE! Async.
        else
          @kbDoc = @refDocs = nil
          @viewMsg = "#{@lastApiReqErrText} Possibly you do not have permission within Genboree; please speak to a project Administrator to arrange access."
          renderPage(:show)
        end
      }
      # NO CODE HERE! Async.
    else # models are nil or Exception sub-class, no sense doing more requests
      @kbDoc = nil
      @viewMsg = 'ERROR: Could not retrieve document metadata from underlying Genboree storage. Possibly you do not have permission within Genboree; please speak to a project Administrator to arrange access.'
      logMsg = @viewMsg
      if(docModel.is_a?(Exception) or refModel.is_a?(Exception))
        err = ( docModel.is_a?(Exception) ? docModel : refModel )
        logMsg = "#{@viewMsg}\n        Error class: #{err.class}\n        Error message: #{err.message}\n        Error trace:\n#{err.backtrace.join("\n") }"
      end
      $stderr.debugPuts(__FILE__, __method__, "GENBOREE AC", "#{logMsg}")
      renderPage(:show)
    end
    # NO CODE HERE! Async.
  end

  # ------------------------------------------------------------------
  # PRIVATE METHODS
  # ------------------------------------------------------------------

  private

end
