require 'brl/util/util'
require 'brl/em/emHttpDeferrableBody.rb'
require 'brl/sites/geneReviews/geneReview'
require 'brl/genboree/kb/helpers/targeted/basicGeneReviewKbDoc'

  
# Helper class for querying GeneReview portal by the redmineKB controller
class GeneReviewHelper
  include GenboreeAcHelper
  attr_accessor :env, :collName, :apiCaller, :fieldMap
  attr_accessor :targetHost, :gbGroup, :gbKb
  attr_accessor :insertNonGRRefAfterCheck
  
  def initialize(grId)
    @grId = grId
    @insertNonGRRefAfterCheck = false
  end
  
  # Redmine Controller Interface
  # Will be called in next_tick
  def start()
    begin
      grObj = BRL::Sites::GeneReviews::GeneReview.fromId(@grId, :eventmachine => true)
      grObj.callback(self, :successHandler)
      grObj.errback(self, :failureHandler)
      grObj.retrieve()
    rescue => err
      $stderr.debugPuts(__FILE__, __method__, "ERROR", err)
      prepareFinalResp(nil, nil)
    end
  end
  
  def successHandler(xmlHash, infoHash)
    prepareFinalResp(xmlHash, infoHash)
  end
  
  def failureHandler(xmlHash, infoHash)
    $stderr.debugPuts(__FILE__, __method__, "STATUS", "GeneReview reference not found.")
    # We have been instructed to insert a non GeneReview (regular) pubmed reference.
    if(@insertNonGRRefAfterCheck)
      $stderr.debugPuts(__FILE__, __method__, "STATUS", "Inserting non GeneReview Pubmed reference.")
      refDoc = { "Reference" => { "value" => "", "properties" => {  "Category" => { "value" => "PMID" }, "PMID" => { "value" => @grId, "properties" => { } }  } } }
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
      apiReq = GbApi::JsonAsyncApiRequester.new(@env, @targetHost, @project)
      apiReq.notifyWebServer = false 
      apiReq.bodyFinish {
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
      }
      fieldMap = { :grp => @gbGroup, :kb => @gbKb, :coll => @collName, :doc => "" }
      apiReq.put(rsrcPath, fieldMap, JSON.generate(refDoc))
    else
      logError(xmlHash, infoHash)
      status = 404
      resp = { 'msg' => "The GeneReview document with id: #{@grId} could not be found. If you believe this GeneReview id exists, please contact a project manager to resolve the issue." }
      sendAsyncResponse(resp, status)
    end
  end
  
  def prepareFinalResp(xmlHash, infoHash)
    begin
      resp = nil
      status = 200
      if(xmlHash.nil?)
        $stderr.debugPuts(__FILE__, __method__, "STATUS", "in prepareFinalResp but xmlHash is nil.")
        logError(xmlHash, infoHash)
        resp = { 'msg' => "The GeneReview document with id: #{@grId} could not be found. If you believe this GeneReview id exists, please contact a project manager to resolve the issue." }
        status = 404
        sendAsyncResponse(resp, status)
      else
        # - instantiate from xmlHash
        basicGRKbDoc = BRL::Genboree::KB::Helpers::Targeted::BasicGeneReviewKbDoc.fromXmlHash(xmlHash)
        # - get as KbDoc object
        grKbDoc = basicGRKbDoc.as_kbDoc()        
        resp = grKbDoc
        # Upload doc to KB
        uploadRefDoc(grKbDoc)
      end
      
    rescue Exception => err
      $stderr.debugPuts(__FILE__, __method__, "ERROR", err)
      $stderr.debugPuts(__FILE__, __method__, "ERROR-TRACE", err.backtrace.join("\n"))
      resp = { 'msg' => "The GeneReview document with id: #{@grId} could not be found. If you believe this GeneReview id exists, please contact a project manager to resolve the issue." }
      sendAsyncResponse(resp, 500)
    end
  end
  
  def logError(xmlHash, infoHash)
    $stderr.debugPuts(__FILE__, __method__, "GENE_REVIEW_ERROR", "infoHash dump:\n#{JSON.pretty_generate(infoHash)}") 
  end

  # This method instantiates the EMDeferrable class and 'triggers' the response cascade by calling 'async.callback'.call()
  #  - Once the response headers are sent out, the EM framework calls the each() in the Deferreable class that we instantiate here.
  def sendAsyncResponse(resp, status)
    $stderr.debugPuts(__FILE__, __method__, "DEBUG", "sending response to client") 
    headers = {}
    headers['Content-Type'] = "text/plain"
    body = BRL::EM::EMHTTPDeferrableBody.new()
    body.call_dequeue = false
    body.responseMessage = JSON.generate(resp)
    body.callSucceedAfterYieldingResponseMessage = true
    @env['async.callback'].call [status, headers, body]
  end
  
  def uploadRefDoc(grKbDoc)
    $stderr.debugPuts(__FILE__, __method__, "STATUS", "GeneReview reference found. Inserting reference.")
    contributionDate = grKbDoc.getPropVal('GeneReview.Contribution Date')
    if(contributionDate.is_a?(Hash))
      year = contributionDate['Year']
      month = contributionDate['Month']
      day = contributionDate['Day']
      grKbDoc.setPropVal('GeneReview.Contribution Date', "#{year}-#{month}-#{day}")
    end
    revisionDate = grKbDoc.getPropVal('GeneReview.Revision Date')
    if(revisionDate.is_a?(Hash))
      year = revisionDate['Year']
      month = revisionDate['Month']
      day = revisionDate['Day']
      grKbDoc.setPropVal('GeneReview.Revision Date', "#{year}-#{month}-#{day}")
    end
    refDoc = { "Reference" => { "value" => "", "properties" => {  "Category" => { "value" => "GeneReview" },  "GeneReview" => { "value" => grKbDoc.getPropVal('GeneReview'), "properties" => grKbDoc['GeneReview']['properties'] } } } }
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
    apiReq = GbApi::JsonAsyncApiRequester.new(@env, @targetHost, @project)
    apiReq.notifyWebServer = false 
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
    }
    fieldMap = { :grp => @gbGroup, :kb => @gbKb, :coll => @collName, :doc => "" }
    apiReq.put(rsrcPath, fieldMap, JSON.generate(refDoc))
  end
  
  
end  
  
