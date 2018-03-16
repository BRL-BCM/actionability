
module GenboreeAcDocHelper
  def self.included(includingClass)
    includingClass.send(:include, KbHelpers::KbProjectHelper)
    includingClass.send(:include, GenboreeAcHelper)
    includingClass.send(:include, GenboreeAcAsyncHelper)
  end

  def self.extended(extendingObj)
    extendingObj.send(:extend, KbHelpers::KbProjectHelper)
    extendingObj.send(:extend, GenboreeAcHelper)
    extendingObj.send(:extend, GenboreeAcAsyncHelper)
  end
  
  # Other helpers used by genboree_ac_doc_controller
  # Document is uploaded to the 'Release' database along with all it's references.
  # Used in both cases where release doc is uploaded for first time (when doc is created in curation/editing KB) and during actual "release" of the doc in the working KB
  # When release doc is uploaded for first time, it must have a status of 'In Preparation', releaseEvent is false and a respObj is provided
  # The name of the collections for both the actionability and the references collection MUST be the same.
  def initUploadReleaseDoc( kbDoc, releaseEvent=true, respObj=nil )
    begin
      # Get the autoid counter value. We may need to 'reserve' an id for this document
      @actionabilityDocId = kbDoc.getPropVal("ActionabilityDocID")
      rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/model/prop/ActionabilityDocID/autoIDs?"
      kbDoc = cleanStage2AutoIDs(kbDoc)
      targetHost = getHost()
      apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq.bodyFinish {
        begin
          kbd = BRL::Genboree::KB::KbDoc.new(apiReq.respBody['data'])
          currCounterVal = kbd.getPropVal('PropPath.Additional Information.Counters.Type.Value').to_i
          #$stderr.debugPuts(__FILE__, __method__, "DEBUG", "currCounterVal:\n#{currCounterVal.inspect}")
          docIdCounter = kbDoc.getPropVal('ActionabilityDocID').gsub(/^AC/, "").to_i
          #$stderr.debugPuts(__FILE__, __method__, "DEBUG", "docIdCounter:\n#{docIdCounter.inspect}")
          # Reserve the docid 
          if( docIdCounter > currCounterVal )
            incrementBy = docIdCounter - currCounterVal
            rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/model/prop/ActionabilityDocID/autoIDs?amount=#{incrementBy}"
            targetHost = getHost()
            apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
            fieldMap = { :coll => @acCurationColl }
            apiReq2.bodyFinish {
              if(apiReq2.respStatus >= 200 and apiReq2.respStatus < 400)
                uploadReleaseDoc(kbDoc, releaseEvent, respObj)
              else
                status = apiReq2.status
                headers = apiReq2.headers
                headers['Content-Type'] = "text/plain"
                apiReq2.sendToClient(status, headers, JSON.generate( apiReq2.respBody ))
              end
            }
            $stderr.debugPuts(__FILE__, __method__, "DEBUG", "Reserving autoID for actionability doc...")
            apiReq2.put(rsrcPath, fieldMap)
          else # We are good. We can do the insert without reserving the auto ids 
            uploadReleaseDoc(kbDoc, releaseEvent, respObj)
          end
        rescue => err
          status = apiReq.status
          headers = apiReq.headers
          headers['Content-Type'] = "text/plain"
          apiReq.sendToClient(status, headers, JSON.generate( apiReq.respBody ))
        end
      }
      apiReq.get(rsrcPath, { :coll => @acCurationColl })
      fieldMap  = { :coll => @acRefColl, :doc => kbDoc.getPropVal('ActionabilityDocID') } 
    rescue => err
      $stderr.debugPuts(__FILE__, __method__, "ERROR", err)
      $stderr.debugPuts(__FILE__, __method__, "ERROR-TRACE", err.backtrace.join("\n"))
      sendResp(@lastApiReq, { "status" => { "msg" => err } }, 500)
    end
  end
  
  def cleanStage2AutoIDs(kbDoc)
    props = kbDoc.getPropProperties('ActionabilityDocID.Stage 2')
    props.each_key { |prop|
      next if(prop == 'Outcomes' or prop == 'Status' or prop == 'Summary')
      subprops = kbDoc.getPropProperties("ActionabilityDocID.Stage 2.#{prop}")
      subprops.each_key { |subprop|
        if(subprops[subprop].key?('properties'))
          cleanStage2PropAutoID(kbDoc.getPropProperties("ActionabilityDocID.Stage 2.#{prop}.#{subprop}"))
        elsif(subprops[subprop].key?('items'))
          items = kbDoc.getPropItems("ActionabilityDocID.Stage 2.#{prop}.#{subprop}")
          if(items and items.length > 0)
            items.each { |itemDoc|
              rootProp = itemDoc.keys[0]
              itemDoc[rootProp]['value'] = ""
              cleanStage2PropAutoID(itemDoc[rootProp]['properties'])
            }
          end
        end
      }
    }
    #$stderr.puts "kbDoc [AFTER cleaning autoID]:\n#{JSON.pretty_generate(kbDoc)}"
    return kbDoc
  end
  
  def cleanStage2PropAutoID(spProps)
    if(spProps.key?('Additional Tiered Statements') )
      items = spProps['Additional Tiered Statements']['items']
      if( items and items.size > 0 )
        items.each {|item|
          rootProp = item.keys[0]
          item[rootProp]['value'] = ""
        }
      end
    elsif(spProps.key?('Additional Statements'))
      items = spProps['Additional Statements']['items']
      if( items and items.size > 0 )
        items.each {|item|
          rootProp = item.keys[0]
          item[rootProp]['value'] = ""
        }
      end
    elsif(spProps.key?('Additional Recommendations'))
      items = spProps['Additional Recommendations']['items']
      if( items and items.size > 0 )
        items.each {|item|
          rootProp = item.keys[0]
          item[rootProp]['value'] = ""
        }
      end
    end
  end
  
  def uploadReleaseDoc(kbDoc, releaseEvent, respObj)
    tt = Time.now.to_f
    rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/doc/{doc}?detailed=true"
    targetHost = getHost()
    fieldMap = { :coll => @acCurationColl, :doc => kbDoc.getPropVal("ActionabilityDocID") }
    targetHost = getHost()
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      if(apiReq.respStatus >= 200 and apiReq.respStatus < 400)
        # This is the full release event when status is changed to 'released' by user
        if(releaseEvent)
          @releaseKBRevision = apiReq.respBody['metadata']['revision']
          # Save released kbdoc for later use post-upload phase
          @releaseKbDoc = kbDoc
          $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "RELEASED kbDoc with #{kbDoc.getRootProp rescue '[FAIL]'}=>#{kbDoc.getRootPropVal rescue '[FAIL]'} via the url #{apiReq.fullApiUrl.inspect} in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
          getDocRefsAsync(kbDoc, @acRefColl, opts={ :replaceWithNums => false}) { |refDocs|
            begin
              if(refDocs and !refDocs.empty?)
                loadAcRefDocs(refDocs) 
              else
                # Update the doc in the working KB with the revision number in the release KB
                apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
                apiReq2.bodyFinish {
                  $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "RELEASED the #{refDocs.size rescue '[N/A!]'} reference docs associated with the released kb in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
                  # Notice: doc released
                  notifyOk = notifyDocReleased()
                  $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Done doc-release MQ notification (ok? #{notifyOk.inspect}) in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
                  sendResp(apiReq2, apiReq2.respBody, apiReq2.respStatus)
                }
                rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
                gbGroup = getGroup()
                gbkb = getKb()
                fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => @acCurationColl, :doc => @actionabilityDocId, :prop => "ActionabilityDocID.Release.kbRevision-PairedKB"  } 
                apiReq2.put(rsrcPath, fieldMap, JSON.generate({"value" => @releaseKBRevision}))
              end
            rescue  => err
              $stderr.debugPuts(__FILE__, __method__, "ERROR", err)
              sendResp(@lastApiReq, { "status" => { "msg" => err } }, 500)
            end
          }
        else # Doc being pushed to release KB for first time ("In Preparation")
          # Notice: doc released
          @releaseKbDoc = kbDoc
          notifyOk = notifyDocReleased()
          $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Done doc-release MQ notification (ok? #{notifyOk.inspect}) in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
          sendResp(apiReq, respObj, apiReq.respStatus)
        end
      else
        status = apiReq.respStatus
        headers = apiReq.respHeaders
        headers['Content-Type'] = "text/plain"
        apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
      end
    }
    apiReq.put(rsrcPath, fieldMap, JSON.generate(kbDoc))
  end

  def loadAcRefDocs(refDocs)
    # Get the last ref id. We may need to reserve the autoIDs in the target collection
    maxId = 0
    refDocs.each {|refDoc|
      kbd = BRL::Genboree::KB::KbDoc.new(refDoc)
      refId = kbd.getPropVal('Reference').gsub(/^RF/, "").to_i
      if( refId > maxId )
        maxId = refId
      end
    }
    targetHost = getHost()
    apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq2.bodyFinish {
      begin
        kbd = BRL::Genboree::KB::KbDoc.new(apiReq2.respBody['data'])
        currCounterVal = kbd.getPropVal('PropPath.Additional Information.Counters.Type.Value').to_i
        if( maxId > currCounterVal ) # We'll need to reserve the autoIds for the target ref collection
          incrementBy = maxId - currCounterVal
          rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/model/prop/Reference/autoIDs?amount=#{incrementBy}"
          apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq.bodyFinish {
            if(apiReq.respStatus >= 200 and apiReq.respStatus < 400)
              uploadRefDocs(refDocs)
            else
              status = apiReq.status
              headers = apiReq.headers
              headers['Content-Type'] = "text/plain"
              apiReq.sendToClient(status, headers, JSON.generate( apiReq.respBody ))
            end
          }
          $stderr.debugPuts(__FILE__, __method__, "DEBUG", "Reserving autoID for ref docs...")
          apiReq.put(rsrcPath, { :coll =>  @acRefColl })
        else
          uploadRefDocs(refDocs)
        end
      rescue => err
        sendResp(apiReq2, { "status" => { "msg" => err } }, 500)
      end
    }
    rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/model/prop/Reference/autoIDs?"
    apiReq2.get(rsrcPath, { :coll => @acRefColl })
  end
  
  def uploadRefDocs(refDocs)
    tt = Time.now.to_f
    rsrcPath = "#{@gbReleaseKbRsrcPath}/coll/{coll}/docs?"
    targetHost = getHost()
    apiReq3 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq3.bodyFinish {
      # Update the doc in the working KB with the revision number in the release KB
      apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq.bodyFinish {
        $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "RELEASED the #{refDocs.size rescue '[N/A!]'} reference docs associated with the released kb in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
        # Notice: doc released
        notifyOk = notifyDocReleased()
        $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Done doc-release MQ notification (ok? #{notifyOk.inspect}) in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
        sendResp(apiReq, apiReq.respBody, apiReq.respStatus)
      }
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/prop/{prop}"
      gbGroup = getGroup()
      gbkb = getKb()
      fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => @acCurationColl, :doc => @actionabilityDocId, :prop => "ActionabilityDocID.Release.kbRevision-PairedKB"  } 
      apiReq.put(rsrcPath, fieldMap, JSON.generate({"value" => @releaseKBRevision}))
      
    }
    fieldMap = { :coll => @acRefColl }
    $stderr.debugPuts(__FILE__, __method__, "DEBUG", "Uploading ref docs...")
    apiReq3.put(rsrcPath, fieldMap, JSON.generate(refDocs))
  end
  
  def sendResp(apiReqObj, respBody, status)
    headers = apiReqObj.respHeaders
    headers['Content-Type'] = "text/plain"
    apiReqObj.sendToClient( status, headers, JSON.generate( respBody ) )
  end
  
  def constructSyndromeRespObj(syndromeDoc)
    #$stderr.puts "syndromeDoc:\n#{JSON.pretty_generate(syndromeDoc)}"
    syndrome = syndromeDoc['value']
    orphs = []
    omims = []
    acrs = []
    overview = ""
    props = syndromeDoc['properties']
    if( props.key?('OmimIDs') )
      omimItems = props['OmimIDs']['items']
      omimItems.each {|oi|
        omims.push(oi['OmimID']['value'])  
      }
    end
    if( props.key?('OrphanetIDs') )
      orphItems = props['OrphanetIDs']['items']
      orphItems.each {|oi|
        orphs.push(oi['OrphanetID']['value'])  
      }
    end
    if( props.key?('Acronyms') )
      acrItems = props['Acronyms']['items']
      acrItems.each {|acr|
        acrs.push(acr['Acronym']['value'])  
      }
    end
    if( props.key?('Overview') )
      overview = props['Overview']['value']
    end
    respData = {}
    respData['syndrome'] = syndrome
    respData['orphanet'] = orphs
    respData['omim'] = omims
    respData['aliases'] = acrs
    respData['overview'] = overview
    resp = {}
    resp['data'] = respData
    return resp
  end

  # @todo move this to some gneric mq helper
  def uniqFileName( fileName )
    baseFn = File.basename( fileName.to_s )
    dir = ( (fileName =~ /\//) ? "#{File.dirname(fileName)}/" : '' )
    uniqStr = fileName.to_s.generateUniqueString
    return "#{dir}#{Time.now.to_f}-#{uniqStr}-#{baseFn}"
  end

  # @todo move this to some generic mq helper. Add other :mqType support (e.g. for real * direct kafka)
  def mqNotify( msgContent, noticeConf, mqConf )
    tt = Time.now.to_f
    retVal = nil
    if( noticeConf[:mqType] == :dir )
      # Is mqConf already the config Hash or do we need to read the config json file it points to?
      unless( mqConf.is_a?(Hash) ) # is String with location of conf json file
        mqConfFile = mqConf
        #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Given location of doc-released MQ conf:\n\t#{mqConfFile.inspect}\n\n")
        mqConf = JSON.parse( File.read( mqConfFile ) ) rescue nil
        #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Loaded conf for doc-released MQ conf w/keys #{mqConf.keys.inspect} in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
      end

      # mqConf and noticeConf hashes look ok? Then write message accordingly
      if( mqConf and mqConf['location'].to_s =~ /\S/ and noticeConf[:subject] =~ /\S/ )
        queueDir = mqConf['location'].to_s.strip
        subject = noticeConf[:subject] # should be a docID in most cases
        msgFile = uniqFileName( "#{queueDir}/#{subject}.json" )
        #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "MQ message file will be: #{msgFile.inspect}")
        File.open(msgFile, 'w+') { |outFile|
          outFile.write( msgContent )
        }
        $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Wrote message for subject #{subject.inspect} to file #{msgFile.inspect} in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
        retVal = true
      else
        msg = "Bad arguments. Could not find and parse message queue config provided (#{mqConfFile.inspect} - syntax error maybe?) or there is no noticeConf[:subject] (#{noticeConf[:subject].inspect rescue '[MISSING]'})! Can't notify WAG Kafka of new doc release."
        $stderr.debugPuts(__FILE__, __method__, '!! FAILED !!', msg)
        raise ArgumentError, msg
      end
    else
      raise ArgumentError, "ERROR: Currently only :mqType=>:dir is supported (and even then probably as a temporary stop-gap measure). Your mqConf[:mqType] was #{mqConf[:mqType].inspect}"
    end
    return retVal
  end

  def notifyDocReleased()
    tt = Time.now.to_f
    retVal = nil
    if( @releaseKbDoc.is_a?(BRL::Genboree::KB::KbDoc) and @releaseKbDoc.getRootPropVal =~ /\S/ )
      docID = @releaseKbDoc.getRootPropVal.to_s.strip
      # Gather info and arrange appropriate kind of release
      # Info for producer
      templateGroup = 'wag-json'
      # @todo move message queuing to helper function that is aware of different types of message (bit like noticeConf above)
      #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "templateGroup: #{templateGroup.inspect} ; currTemplateSet():\n\n#{JSON.pretty_generate(currTemplateSet()) rescue currTemplateSet().inspect}\n\n")
      producerOpts = {
        :templateDir => templateGroupDir( templateGroup, currTemplateSet() ),
        # Options generally related to reports or anything that shows the version-based permaline, the current version link,
        # and which renders a particular version of the doc as a report. Here, these aren't really relevant so we'll avoid filling them in.
        :viewingHeadVersion   => true,
        :viewAcDocVersion     => nil,
        :headAcDocVersion     => nil,
        # Producer settings suitable for templates that make JSON
        :skipValidation       => true,
        :skipVariabilization  => true, # big speed up! >20X faster rendering without deprecated variablization feature
        :relaxedRootValidation   => true,
        :supressNewlineAfterItem => true,
        :itemPostfix          => '', # supress default extra space after items (invisible in HTML, but not in JSON)
        :context              => { }
      }
      producerOpts[:context][:requestUrl]          = request.url
      producerOpts[:context][:releaseKbRsrcPath]   = @settingsRec.gbReleaseKbRsrcPath
      producerOpts[:context][:releaseRptBase]      = @settingsRec.releaseKbBaseUrl
      producerOpts[:context][:actionabilityColl]   = @settingsRec.actionabilityColl
      # Create producer
      docProducer = BRL::Genboree::KB::Producers::AbstractTemplateProducer.new( @model, @releaseKbDoc, producerOpts )
      # Render
      template = :docSummaryBase
      #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Ready to render doc to message in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
      renderedStr = docProducer.render( template )
      #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Done render doc to message in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
      # Queue notification message
      noticeConf = { :mqType => :dir, :subject => @releaseKbDoc.getRootPropVal }
      #mqConfFile = '/usr/local/brl/local/rails/redmine_genbKB_dev/var/messages/conf/ac-release-wag.json'
      retVal = mqNotify( renderedStr, noticeConf, @settingsRec.releasedMqConf )
      $stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Queued message in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
      #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Going to see what happens if queue 5 more very fast...")
      #5.times { |ii|
      #  mqNotify( renderedStr, noticeConf, @settingsRec.releasedMqConf )
      #}
      #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "Queued 5 more FAKE messages (should all be uniq) in #{Time.now.to_f - tt} sec") ; tt = Time.now.to_f
    end
    return retVal
  end
end
