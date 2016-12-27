#require 'plugins/genboree_ac/app/helpers/gene_review_helper'

class GenboreeAcReferencesController < ApplicationController
  include GenboreeAcHelper

  respond_to :json
  before_filter :find_project

  unloadable

  def show()
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}"
    acCollName  = params['acCurationColl']
    refCollName = params['acRefColl']
    docId     = params['docIdentifier']
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => acCollName, :doc => docId }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      if( apiReq.respBody['data'] )
        doc = apiReq.respBody['data']
        if(doc and doc['ActionabilityDocID']['properties']['Stage 2'])
          refList = createRefList(doc)
          if(refList.keys.size > 0)
            rsrcPath2 = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?matchProp=Reference&matchMode=exact&detailed=true&matchValues={vals}"
            fieldMap2  = { :grp => gbGroup, :kb => gbkb, :coll => refCollName, :vals => refList.keys }
            apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
            apiReq2.bodyFinish {
              headers2 = apiReq2.respHeaders
              status2 = apiReq2.respStatus
              headers2['Content-Type'] = "text/plain"
              apiReq2.sendToClient( status2, headers2, JSON.generate( apiReq2.respBody ) )
            }
            apiReq2.get(rsrcPath2, fieldMap2)
          else
            # No references
            apiReq.sendToClient( status, headers, JSON.generate( { "data" => [] } ) )
          end
        else
          apiReq.sendToClient( status, headers, JSON.generate( { "data" => [] } ) )
        end
      else
        apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
      end
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  
  def update()
    refId = params['refId']
    collName = params['acRefColl']
    otherRefSubDoc = JSON.parse(params['value'])
    refDoc = { "Reference" => { "value" => refId, "properties" => {  "Category" => { "value" => 'Other' }, "Other Reference" => { "properties" => otherRefSubDoc }  } } }
    fieldMap  = { :coll => collName, :doc => refId }
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
    apiResult = apiPut(rsrcPath, refDoc.to_json, fieldMap)
    respObj = apiResult[:respObj]
    respond_with(respObj, :status => apiResult[:status], :location => "")
  end
  
  def reference()
    matchValue = params['value']
    category = params['category']
    # First, check to see if the reference entered by the user already exists in our collection.
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?"
    props = []
    categoryValue = nil
    if(category == 'Pubmed')
      rsrcPath << "matchProps={props}&matchValue={mv}&matchMode=exact&detailed=true"
      props.push("Reference.PMID")
      props = ["Reference.PMID", "Reference.GeneReview.PMID"]
      categoryValue = 'PMID'
    elsif(category == 'OMIM')
      rsrcPath << "matchProps={props}&matchValue={mv}&matchMode=exact&detailed=true"
      props.push("Reference.OMIM")
      categoryValue = 'OMIM'
    elsif(category == 'GeneReview')
      rsrcPath << "matchProps={props}&matchValue={mv}&matchMode=exact&detailed=true"
      props = [ 'Reference.GeneReview', 'Reference.GeneReview.PMID' ]
      categoryValue = 'GeneReview'
    elsif(category == 'Orphanet')
      rsrcPath << "matchProps={props}&matchValue={mv}&matchMode=exact&detailed=true"
      props.push("Reference.Orphanet")
      categoryValue = 'Orphanet'
    else
      categoryValue = "Other"
    end
    collName = params['acRefColl']
    if(categoryValue != "Other")
      acOnetCollRsrcPath = params['acOnetCollRsrcPath']
      fieldMap  = { :coll => collName, :mv => matchValue, :props => props }
      apiResult  = apiGet(rsrcPath, fieldMap)
      respObj = nil
      if(apiResult[:status] == 200 and apiResult[:respObj]['data'] and !apiResult[:respObj]['data'].empty?)
        $stderr.debugPuts(__FILE__, __method__, "STATUS", "Found reference in collection.")
        respObj = { "data" => apiResult[:respObj]['data'][0] }
        respond_with(respObj, :status => apiResult[:status], :location => "")
      else
        $stderr.debugPuts(__FILE__, __method__, "STATUS", "Reference not found in collection.")
        rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
        fieldMap  = { :coll => collName, :doc => "" }
        if(category == 'OMIM')
          refDoc = { "Reference" => { "value" => "", "properties" => {  "Category" => { "value" => categoryValue }, categoryValue => { "value" => matchValue, "properties" => { } }  } } }
          apiResult = apiPut(rsrcPath, refDoc.to_json, fieldMap)
          respObj = apiResult[:respObj]
          respond_with(respObj, :status => apiResult[:status], :location => "")
        elsif(category == 'GeneReview' || category == 'Pubmed')
          $stderr.debugPuts(__FILE__, __method__, "STATUS", "Start async lookup for GeneReview.")
          grh = GeneReviewHelper.new(matchValue)
          grh.env = env
          grh.targetHost = getHost()
          grh.gbGroup = getGroup()
          grh.gbKb = getKb()
          grh.collName = collName
          grh.insertNonGRRefAfterCheck = true if(category == 'Pubmed')
          EM.next_tick {
            grh.start()
          }
          throw :async
        elsif(category == 'Orphanet')
          # We will have to look up the Orphanet mirror collection
          apiResult  = apiGet("#{acOnetCollRsrcPath.chomp("?")}/doc/{doc}?", { :doc => matchValue })
          if(apiResult[:status] != 200) # The cache does not have this reference.
            respond_with({}, :status => apiResult[:status], :location => "")
          else
            # We have a document. Insert it in the references collection
            $stderr.debugPuts(__FILE__, __method__, "STATUS", "Found reference in mirror/cache collection.")
            doc = apiResult[:respObj]['data']
            refDoc = { "Reference" => { "value" => "", "properties" => {  "Category" => { "value" => categoryValue }, "Orphanet" => doc['Orphanet']  } } }
            $stderr.puts "refdoc:\n\n#{JSON.pretty_generate(refDoc)}"
            apiResult = apiPut(rsrcPath, refDoc.to_json, fieldMap)
            respObj = apiResult[:respObj]
            respond_with(respObj, :status => apiResult[:status], :location => "")
          end
        end
      end
    else # There's no lookup for 'Other' reference. Just do the insert
      # matchValue is the subdoc for other reference
      otherRefSubDoc = JSON.parse(matchValue)
      refDoc = { "Reference" => { "value" => "", "properties" => {  "Category" => { "value" => 'Other' }, "Other Reference" => { "properties" => otherRefSubDoc }  } } }
      $stderr.puts "refdoc:\n\n#{JSON.pretty_generate(refDoc)}"
      fieldMap  = { :coll => collName, :doc => "" }
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
      apiResult = apiPut(rsrcPath, refDoc.to_json, fieldMap)
      respObj = apiResult[:respObj]
      respond_with(respObj, :status => apiResult[:status], :location => "")
    end
    
  end

  # ------------------------------------------------------------------
  # PRIVATE HELPERS
  # ------------------------------------------------------------------
  def createRefList(doc)
    props = doc['ActionabilityDocID']['properties']['Stage 2']['properties']
    refList = {}
    props.each_key {|prop|
      if(prop == 'Outcomes' or prop == 'Status' or prop == 'Summary')
        next
      end
      if(props[prop]['properties'])
        props[prop]['properties'].each_key {|subprop|
          if(props[prop]['properties'][subprop]['items'] and props[prop]['properties'][subprop]['items'].size > 0)
            rootProp = props[prop]['properties'][subprop]['items'][0].keys[0]
            props[prop]['properties'][subprop]['items'].each_index {|idx|
              props[prop]['properties'][subprop]['items'][idx][rootProp]['properties'].each_key { |childProp|
                if(childProp == 'References' and props[prop]['properties'][subprop]['items'][idx][rootProp]['properties'][childProp].key?('items'))
                  props[prop]['properties'][subprop]['items'][idx][rootProp]['properties'][childProp]['items'].each_index {|refObjIdx|
                    refObj = props[prop]['properties'][subprop]['items'][idx][rootProp]['properties'][childProp]['items'][refObjIdx]
                    refId = refObj['Reference']['value'].split("/").last
                    refList[CGI.unescape(refId)] = nil  if(!refId.nil?)
                  }
                end
              }
            }
          elsif(props[prop]['properties'][subprop]['properties'])
            props[prop]['properties'][subprop]['properties'].each_key {|childProp|
              if(childProp == 'References' and props[prop]['properties'][subprop]['properties'][childProp].key?('items'))
                props[prop]['properties'][subprop]['properties'][childProp]['items'].each_index {|refObjIdx|
                  refObj = props[prop]['properties'][subprop]['properties'][childProp]['items'][refObjIdx]
                  refId = refObj['Reference']['value'].split("/").last
                  refList[CGI.unescape(refId)] = nil  if(!refId.nil?)
                }
              end

            }
          end
        }
      end
    }
    return refList
  end


end
