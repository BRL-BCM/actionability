#require 'plugins/genboree_ac/app/helpers/gene_review_helper'

class GenboreeAcReferencesController < ApplicationController
  include GenboreeAcDocHelper
  
  respond_to :json
  before_filter :find_project, :genboreeAcSettings
  STAGE2_SECTIONS_REF_ORDER = [
    { :name => "Nature of the Threat", :props => ["Prevalence of the Genetic Disorder", "Clinical Features", "Natural History"] },
    { :name => "Effectiveness of Intervention", :props => ["Patient Managements", "Surveillances", "Family Managements", "Circumstances to Avoid"] },
    { :name => "Threat Materialization Chances", :props => ["Mode of Inheritance", "Prevalence of the Genetic Mutation", "Penetrances", "Relative Risks", "Expressivity Notes"] },
    { :name => "Acceptability of Intervention", :props => ["Natures of Intervention"] },
    { :name => "Condition Escape Detection", :props => ["Chances to Escape Clinical Detection"] }
  ]
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
              docs = apiReq2.respBody['data']
              docHash = {}
              sortedDocs = []
              docs.each { |doc|
                kbd = BRL::Genboree::KB::KbDoc.new(doc)
                refId = kbd.getPropVal("Reference")
                docHash[refList[refId]] = kbd
              }
              docs.size.times { |ii|
                sortedDocs <<  docHash[ii]
              }
              headers2['Content-Type'] = "text/plain"
              apiReq2.sendToClient( status2, headers2, JSON.generate( { "data" => sortedDocs } ) )
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
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => refId }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      headers['Content-Type'] = "text/plain"
      apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
    }
    apiReq.put(rsrcPath, fieldMap, JSON.generate(refDoc))
  end
  
  # Remove a specific reference from an actionability doc
  # Will remove all citations of the reference.
  def remove()
    refId = params['refId']
    collName = params['acCurationColl']
    docId     = params['docIdentifier']
    rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => docId }
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      begin
        if(apiReq.respStatus >= 200 and apiReq.respStatus < 400)
          kbd = BRL::Genboree::KB::KbDoc.new(apiReq.respBody['data'])
          # First remove the reference from under Stage 2
          paths = kbd.getMatchingPaths(/References$/)
          paths.each { |path|
            refs = kbd.getPropItems(path)
            if(refs and !refs.empty?)
              idx = 0
              refs.each { |refObj|
                refkbd =  BRL::Genboree::KB::KbDoc.new(refObj)
                if(refkbd.getPropVal('Reference').split("/").last == refId)
                  refs.delete_at(idx)
                end
                idx += 1
              }
            end
          }
          # Next remove the reference under RefMetadata (which contains any user uploaded file for that reference)
          refMdDoc = kbd.getSubDoc("ActionabilityDocID.RefMetadata")['RefMetadata']
          if(!refMdDoc.nil? and refMdDoc.key?('items'))
            refs = kbd.getPropItems("ActionabilityDocID.RefMetadata")
            if(refs and !refs.empty?)
              idx = 0
              refs.each { |refObj|
                refkbd =  BRL::Genboree::KB::KbDoc.new(refObj)
                if(refkbd.getPropVal('Reference').split("/").last == refId)
                  refs.delete_at(idx)
                end
                idx += 1
              }
            end
          end
          # Upload the doc
          apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq2.bodyFinish {
            headers = apiReq2.respHeaders
            headers['Content-Type'] = "text/plain"
            apiReq2.sendToClient(apiReq2.respStatus, headers, JSON.generate(apiReq2.respBody))
          }
          apiReq2.put(rsrcPath, fieldMap, JSON.generate(kbd))
        else
          headers = apiReq.respHeaders
          headers['Content-Type'] = "text/plain"
          apiReq.sendToClient(apiReq.respStatus, headers, JSON.generate(apiReq.respBody))
        end
      rescue => err
        headers = apiReq.respHeaders
        headers['Content-Type'] = "text/plain"
        respObj = { "status" => { "statusCode" => "Internal Server Error", "msg" => err }}
        $stderr.debugPuts(__FILE__, __method__, 'ERROR', err)
        $stderr.debugPuts(__FILE__, __method__, 'ERROR-TRACE', err.backtrace.join("\n"))
        apiReq.sendToClient(500, headers, JSON.generate(respObj))
      end
      
      
      
    }
    apiReq.get(rsrcPath, fieldMap)
  end
  
  def reference()
    # This action is also used by the create new modal for checking if the omim id entered exists or not. Implement backwards-compatible default to support it.
    matchValue = ( params['value'] ? params['value'] : params['omim'].split(",").last )
    category = ( params['category'] ? params['category'] : "OMIM" )
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
    collName = @acRefColl
    targetHost = getHost()
    gbGroup = getGroup()
    gbkb = getKb()
    if(categoryValue != "Other")
      acOnetCollRsrcPath = params['acOnetCollRsrcPath']
      fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :mv => matchValue, :props => props }
      apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq.bodyFinish {
        headers = apiReq.respHeaders
        status = apiReq.respStatus
        headers['Content-Type'] = "text/plain"
        respObj = nil
        if(status == 200 and apiReq.respBody['data'] and !apiReq.respBody['data'].empty?)
          $stderr.debugPuts(__FILE__, __method__, "STATUS", "Found reference in collection.")
          #respObj = { "data" => apiResult[:respObj]['data'][0] }
          apiReq.sendToClient(status, headers, JSON.generate({ "data" => apiReq.respBody['data'][0] }))
          #respond_with(respObj, :status => apiResult[:status], :location => "")
        else
          $stderr.debugPuts(__FILE__, __method__, "STATUS", "Reference not found in collection.")
          rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
          fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => "" }
          if(category == 'OMIM')
            refDoc = { "Reference" => { "value" => "", "properties" => {  "Category" => { "value" => categoryValue }, categoryValue => { "value" => matchValue, "properties" => { } }  } } }
            
            apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
            apiReq2.bodyFinish{
              headers = apiReq2.respHeaders
              status = apiReq2.respStatus
              headers['Content-Type'] = "text/plain"
              apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody) ) 
            }
            apiReq2.put(rsrcPath, fieldMap, JSON.generate(refDoc))
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
          elsif(category == 'Orphanet')
            # We will have to look up the Orphanet mirror collection
            apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
            apiReq2.bodyFinish{
              headers = apiReq2.respHeaders
              status = apiReq2.respStatus
              if(status != 200) # The cache does not have this reference.
                #respond_with({}, :status => apiResult[:status], :location => "")
                apiReq2.sendToClient(status, headers, JSON.generate({}) ) 
              else
                # We have a document. Insert it in the references collection
                $stderr.debugPuts(__FILE__, __method__, "STATUS", "Found reference in mirror/cache collection.")
                doc = apiReq2.respBody['data']
                refDoc = { "Reference" => { "value" => "", "properties" => {  "Category" => { "value" => categoryValue }, "Orphanet" => doc['Orphanet']  } } }
                $stderr.puts "refdoc:\n\n#{JSON.pretty_generate(refDoc)}"
                apiReq3 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
                apiReq3.bodyFinish{
                  headers = apiReq3.respHeaders
                  status = apiReq3.respStatus
                  headers['Content-Type'] = "text/plain"
                  apiReq3.sendToClient(status, headers, JSON.generate(apiReq3.respBody) ) 
                }
                apiReq3.put(rsrcPath, fieldMap, JSON.generate(refDoc))
              end
            }
            apiReq2.get("#{acOnetCollRsrcPath.chomp("?")}/doc/{doc}?", { :doc => matchValue })
          end
        end
      }
      apiReq.get(rsrcPath, fieldMap)
    else # There's no lookup for 'Other' reference. Just do the insert
      # matchValue is the subdoc for other reference
      otherRefSubDoc = JSON.parse(matchValue)
      refDoc = { "Reference" => { "value" => "", "properties" => {  "Category" => { "value" => 'Other' }, "Other Reference" => { "properties" => otherRefSubDoc }  } } }
      $stderr.puts "refdoc:\n\n#{JSON.pretty_generate(refDoc)}"
      fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => collName, :doc => "" }
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}?detailed=true"
      apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq2.bodyFinish{
        headers = apiReq2.respHeaders
        status = apiReq2.respStatus
        headers['Content-Type'] = "text/plain"
        apiReq2.sendToClient(status, headers, JSON.generate(apiReq2.respBody) ) 
      }
      apiReq2.put(rsrcPath, fieldMap, JSON.generate(refDoc))
    end
    
  end

  # ------------------------------------------------------------------
  # PRIVATE HELPERS
  # ------------------------------------------------------------------
  def addRefsToRefList(refItems, refList, refIdx)
    refItems.each { |refObj|
      kbRefObj =  BRL::Genboree::KB::KbDoc.new(refObj)
      refUrl = kbRefObj.getPropVal('Reference')
      refId = refUrl.split("/").last
      if(refId and !refList.key?(refId))
        refList[refId] = refIdx
        refIdx += 1
      end
    }
    return refIdx 
  end
  
  def scanForRefs(props, refList, refIdx)
    if(props.key?('References') and props['References']['items'] and props['References']['items'].size > 0)
      refItems = props['References']['items']
      refIdx = addRefsToRefList(refItems, refList, refIdx)
    end
    if(props.key?('Additional Tiered Statements') and props['Additional Tiered Statements']['items'] and props['Additional Tiered Statements']['items'].size > 0)
      atsItems = props['Additional Tiered Statements']['items']
      atsItems.each { |atsObj|
        kbAtsObj =   BRL::Genboree::KB::KbDoc.new(atsObj)
        atsProps = kbAtsObj.getPropProperties("RecommendationID")
        if(atsProps.key?("References"))
          refItems = kbAtsObj.getPropItems("RecommendationID.References")
          refIdx = addRefsToRefList(refItems, refList, refIdx)
        end
      }
    end
    return refIdx
  end
  
  def createRefList(doc)
    kbd = BRL::Genboree::KB::KbDoc.new(doc)
    props = kbd.getPropProperties('ActionabilityDocID.Stage 2')
    refList = {}
    refIdx = 0
    STAGE2_SECTIONS_REF_ORDER.each { |obj|
      prop = obj[:name]
      childProps = obj[:props]
      if(props.key?(prop))
        childProps.each{ |cp|
          if(props[prop]['properties'].key?(cp))
            if(props[prop]['properties'][cp].key?('properties'))
              refIdx = scanForRefs(props[prop]['properties'][cp]['properties'], refList, refIdx)
            elsif(props[prop]['properties'][cp].key?('items'))
              propItems = props[prop]['properties'][cp]['items']
              propItems.each { |pitem|
                kbdItem = BRL::Genboree::KB::KbDoc.new(pitem)
                rootProp = pitem.keys[0]
                itemProps = kbdItem.getPropProperties(rootProp)
                refIdx = scanForRefs(itemProps, refList, refIdx)
              }
            end
          end
        }
      end
    }
    return refList
  end


end
