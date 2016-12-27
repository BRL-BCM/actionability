
class GenboreeAcUiStg1RuleOutReportController < ApplicationController
  class GenboreeAcUiStg1RuleOutReportControllerError < StandardError; end

  include GenboreeAcUiStg1RuleOutReportHelper

  respond_to :json

  before_filter :find_project, :authorize, :plugin_proj_settings
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
      # Get the model...need it for rendering.
      # First, get the doc model
      getModelAsync(@acCurationColl) { |docModel|
        @docModel = docModel
        $stderr.debugPuts(__FILE__, __method__, '++++++ DEBUG', "Getting doc model #{(docModel.is_a?(Hash) and @lastApiReqErrText.nil?) ? 'SUCCEEDED' : 'FAILED'}")
        # Now that we have the models, async get and process the doc
        processDoc(@docModel)
      }
      # NO CODE HERE! Async.
    else
      # No doc identifier. Can reply immediately with error message.
      @kbDoc = nil
      @viewMsg = "Missing doc identifier / bad url."
      renderPage(:show)
    end
  end

  def processDoc(docModel=@docModel)
    if(docModel and !docModel.is_a?(Exception))
      # Get the AC doc from Genboree
      getDocAsync(@docIdentifier, @acCurationColl) { |kbDoc|
        @kbDoc = kbDoc
        if(@kbDoc.is_a?(BRL::Genboree::KB::KbDoc) and @lastApiReqErrText.nil?)
          @kbDoc = trimDoc(@kbDoc) if(@trim)
        else
          @kbDoc = nil
          @viewMsg = "#{@lastApiReqErrText} Possibly you do not have permission within Genboree; please speak to a project Administrator to arrange access."
        end
        $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "@kbDoc:\n\n#{@kbDoc.class.inspect}")
        # Regardless of how things look, we should be set up to render some kind of view
        renderPage(:show)
      }
      # NO CODE HERE. Async.
    else # model is nil or Exception sub-class, no sense doing more requests
      @kbDoc = nil
      @viewMsg = 'ERROR: Could not retrieve document metadata from underlying Genboree storage. Possibly you do not have permission within Genboree; please speak to a project Administrator to arrange access.'
      logMsg = @viewMsg
      if(docModel.is_a?(Exception))
        err = docModel
        logMsg = "#{@viewMsg}\n        Error class: #{err.class}\n        Error message: #{err.message}\n        Error trace:\n#{err.backtrace.join("\n") }"
      end
      $stderr.debugPuts(__FILE__, __method__, "GENBOREE AC", "#{logMsg}")
      renderPage(:show)
    end
    # NO CODE HERE. Async.
  end

  # ------------------------------------------------------------------
  # PRIVATE METHODS
  # ------------------------------------------------------------------

  private

end
