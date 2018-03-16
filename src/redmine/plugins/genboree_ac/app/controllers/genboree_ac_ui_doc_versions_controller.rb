require 'time'

class GenboreeAcUiDocVersionsController < ApplicationController
  include GenboreeAcDocHelper
  include GenboreeAcHelper::PermHelper
  include GbMixin::AsyncRenderHelper
  unloadable
  layout 'ac_bootstrap_extensive_hdr_ftr'
  # @todo No, :genboreeAcSettings should be removed [even from SVN] ; the generic find_settings has long been available and should be used.
  before_filter :find_project, :genboreeAcSettings, :authorize, :find_settings

  def show()
    # @todo dynamically set @removeLayout from database record
    @docIdentifier = params['doc'] || nil
    @errMsg = "Unknown Error. Please contact the project administrator to resolve this issue."
    @errorFound = false

    # What *content* fields to get for each version record?
    # - Include Item root props or Item sub-probs if you want values for those
    # - By default, will get just the VALUES of listed fields rather than getting whole
    #   subtrees that include stuff that YOU DON'T NEED.
    # - If you need subtrees (often don't, even for item lists where you just specify the item
    #   root prop and specific item subprops you need the value for), maybe because you iterate
    #   over the various props rather than be specific about which you need, then provide contentFieldsValue=valueObj
    contentFields = [
      "ActionabilityDocID.Release",
      "ActionabilityDocID.Syndrome",
      "ActionabilityDocID.Genes",
      "ActionabilityDocID.Status",
      "ActionabilityDocID.Stage 2.Outcomes",
      "ActionabilityDocID.Stage 2.Effectiveness of Intervention",
      "ActionabilityDocID.Stage 1.Final Stage1 Report.Status"
    ]
    # By default, doc/{docId}/vers will also give you 3 the values for version metadata properties:
    # * versionNum
    # * timestamp
    # * author
    # If these are not sufficient (or too much) provide your own list via versionFields={vf} parameter to URL.
    # These are separate from the *content* [doc] fields.

    # What normal/large col grid sizes to use?
    # - Use instance variable to coordinate with partials that needs same/sync'd info
    @colSizes = {
      :md => {
        :version        => 'col-md-2',
        :release        => 'col-md-1',
        :status         => "col-md-2",
        :date           => 'col-md-1',
        :outcomes       => 'col-md-1',
        :interventions  => 'col-md-2',
        :guidelines     => 'col-md-3'
      }
    }
    # Overrides for release since has no version count column
    if( @settingsRec.isAcReleaseTrack )
      @colSizes[:md][:version] = nil
      @colSizes[:md][:outcomes] = 'col-md-2'
      @colSizes[:md][:release] = 'col-md-2'
    end

    if(@docIdentifier and @docIdentifier != "")
      @genboreeAc = GenboreeAc.find_by_project_id(@projectId)
      @userPermsJS = pluginUserPerms(:genboree_ac, @project, @currRmUser, :as => :javascript)
      @litSearchSourceJSON = getLitSearchSourceHashJSON()
      
      targetHost = getHost()
      gbGroup = getGroup()
      gbkb = getKb()
      initRackEnv( env ) 
      controller = self
      @showLimit = 25
      #@showLimit = 3
      @skip = ( params.key?('skip') ? params['skip'].to_i : 0 )
      rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true"
      fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => @acTemplateSetsColl }
      @endReached = false
      # Get the template document to skip versions that have version number < minAcDocVer for 0th rank template set
      # @todo Use TemplateSetHelper#loadTemplateSetsDoc with callback
      apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
      apiReq.bodyFinish {
        begin
          # @todo No, TemplateSetHelper#loadTemplateSetsDoc has provided @templateSetsDoc
          templateDoc = BRL::Genboree::KB::KbDoc.new(apiReq.respBody['data'][0])
          # @todo No, TemplateSetHelper#loadTemplateSetsDoc has provided @templateSets
          templateSets = templateDoc.getPropItems("TemplateSetDocID.TemplateSets")
          # @todo No, use TemplateSetHelper#minAcDocVer to get this. Will use the already-available @templateSets by default
          templateSets.each { |ts|
            tsDoc = BRL::Genboree::KB::KbDoc.new(ts)
            if(tsDoc.getPropVal("TemplateSet.Rank") == 0)
              @minAcDocVer = tsDoc.getPropVal("TemplateSet.MinAcDocVer").to_i
              break 
            end
          }

          rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/vers?detailed=true&sort=DESC&contentFields={cf}&contentFieldsValue=valueObj&skip={skip}&limit={lm}"
          @viewObj = []
          fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => @acCurationColl, :doc => @docIdentifier, :cf => contentFields, :skip => @skip, :lm => @showLimit }
          # Get the revisions for the doc provided
          #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "#{@showLimit.inspect} versions starting at idx #{@skip.inspect} for doc #{@docIdentifier.inspect} via:\n\trsrcPath:\t#{rsrcPath.inspect}\n\tfieldMap:\t#{fieldMap.inspect}\n\n")
          apiReq2 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
          apiReq2.bodyFinish {
            begin
              if(apiReq2.respStatus >= 200 and apiReq2.respStatus < 400)
                docVersions = apiReq2.respBody['data']
                #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "docVersions payload from #{apiReq2.fullApiUrl.inspect}:\n\n#{JSON.pretty_generate( apiReq2.apiDataObj ) rescue apiReq2.apiDataObj.inspect}")
                ii = 0
                docVersions.each { |dv|
                  dvKbd = BRL::Genboree::KB::KbDoc.new(dv)
                  kbd = BRL::Genboree::KB::KbDoc.new(dvKbd.getPropVal('versionNum.content'))
                  releaseVer = nil
                  versionNum = dvKbd.getPropVal('versionNum').to_i
                  timeObj = Time.parse(dvKbd.getPropVal("versionNum.timestamp"))
                  date = timeObj.strftime("%Y/%m/%d")
                  if(ii == 0)
                    @syndrome = kbd.getPropVal("ActionabilityDocID.Syndrome")
                    geneList = kbd.getPropItems("ActionabilityDocID.Genes") ;
                    @genes = []
                    if( geneList )
                      geneList.each { |geneObj|
                        geneDoc = BRL::Genboree::KB::KbDoc.new(geneObj)
                        @genes <<  geneDoc.getPropVal("Gene")
                      }
                    end
                  end
                  # Since we are going in descencing order, as soon as the version number becomes less than the minimum version supported for the 0th template set, we are done
                  if(versionNum < @minAcDocVer)
                    @endReached = true
                    break
                  end
                  kbdProps = kbd.getPropProperties("ActionabilityDocID")
                  if(kbdProps.key?("Release"))
                    releaseVer = kbd.getPropVal("ActionabilityDocID.Release")
                  end
                  numOutcomes = 0
                  numInterventions = 0
                  guidelines = {
                    "Patient Managements" => 0,
                    "Family Managements" => 0,
                    "Surveillances" => 0,
                    "Circumstances to Avoid" => 0
                  }
                  if(kbdProps.key?("Stage 2"))
                    stage2Props = kbd.getPropProperties("ActionabilityDocID.Stage 2")
                    if(stage2Props)
                      if(stage2Props.key?("Outcomes"))
                        outcomes = kbd.getPropItems("ActionabilityDocID.Stage 2.Outcomes")
                        outcomes.each { |outcomeObj|
                          outcomeDoc = BRL::Genboree::KB::KbDoc.new(outcomeObj)
                          outcomeDocProps = outcomeDoc.getPropProperties("Outcome")
                          numOutcomes += 1
                          if(outcomeDocProps.key?("Interventions"))
                            numInterventions += (outcomeDoc.getPropItems("Outcome.Interventions").size)
                          end
                        }
                      end
                      if(stage2Props.key?("Effectiveness of Intervention"))
                        effProps = kbd.getPropProperties("ActionabilityDocID.Stage 2.Effectiveness of Intervention")
                        effProps.each_key { |prop|
                          guidelines[prop] = kbd.getPropItems("ActionabilityDocID.Stage 2.Effectiveness of Intervention.#{prop}").size
                        }
                      end
                    end
                  end
                  stage1Status = "Incomplete"
                  if(kbdProps.key?("Stage 1"))
                    stage1Props = kbd.getPropProperties("ActionabilityDocID.Stage 1")
                    if(stage1Props.key?("Final Stage1 Report"))
                      stage1Status = kbd.getPropVal("ActionabilityDocID.Stage 1.Final Stage1 Report.Status")
                    end
                  end
                  docStatus = kbd.getPropVal("ActionabilityDocID.Status")
                  @viewObj << { "releaseVer" =>  releaseVer, "versionNum" => versionNum.to_i, "date" => date, "numOutcomes" => numOutcomes, "numInterventions" => numInterventions, "guidelines" => guidelines, "stage1Status" => stage1Status, "docStatus" => docStatus }
                  ii += 1
                }
                if(@skip == 0)
                  apiReq3 = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
                  apiReq3.bodyFinish {
                    begin
                      @totalVers = apiReq3.respBody['data']['count']['value'].to_i
                      renderToClient(controller)
                    rescue => err
                      headers = apiReq.respHeaders
                      status = apiReq.respStatus
                      headers['Content-Type'] = "text/plain"
                      respBody = JSON.generate(apiReq.respBody)
                      $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Exception raised.\n  - Error Class: #{err.class}\nError Message: #{err.message}\n  - Error Trace:\n#{err.backtrace.join("\n")}")
                      apiReq.sendToClient(status, headers, "Error: failure while getting version record count.")
                    end
                  }
                  rsrcPath = "/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/doc/{doc}/vers/count?minDocVersion={minDocVersion}"
                  fieldMap  = { :grp => gbGroup, :kb => gbkb, :coll => @acCurationColl, :doc => @docIdentifier, :minDocVersion => @minAcDocVer }
                  apiReq3.get(rsrcPath, fieldMap)
                else
                  @totalVers = params['totalVers'].to_i
                  renderToClient(controller, {:partial => "genboree_ac_ui_doc_versions/version_records", :layout => false})
                end
              else
                @errorFound = true
                @errMsg = "Error encountered when retrieving document #{@docIdentifier}. It is possible that you do not have access to this document or this document does not exist."
                if(@skip == 0)
                  renderToClient(controller)
                else
                  headers = apiReq2.respHeaders
                  status = apiReq2.respStatus
                  headers['Content-Type'] = "text/plain"
                  apiReq2.sendToClient(status, headers, @errMsg)
                end
              end
            rescue => err
              @viewObj = []
              #$stderr.puts "ERROR - #{__method__}() => Exception! #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}\n\n"
              headers = apiReq2.respHeaders
              status = apiReq2.respStatus
              headers['Content-Type'] = "text/plain"
              respBody = JSON.generate(apiReq2.respBody)
              $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Exception raised.\n  - Error Class: #{err.class}\nError Message: #{err.message}\n  - Error Trace:\n#{err.backtrace.join("\n")}")
              apiReq2.sendToClient(status, headers, "Error: failure while getting version records.")
            end
          }
          apiReq2.get(rsrcPath, fieldMap)
        rescue => err
          @viewObj = []
          #$stderr.puts "ERROR - #{__method__}() => Exception! #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}\n\n"
          headers = apiReq.respHeaders
          status = apiReq.respStatus
          headers['Content-Type'] = "text/plain"
          respBody = JSON.generate(apiReq.respBody)
          $stderr.debugPuts(__FILE__, __method__, 'ERROR', "Exception raised.\n  - Error Class: #{err.class}\nError Message: #{err.message}\n  - Error Trace:\n#{err.backtrace.join("\n")}")
          apiReq.sendToClient(status, headers, "Error: failure while getting template sets information.")
        end
      }
      
      apiReq.get(rsrcPath, fieldMap)
    else
      @errorFound = true
      @errMsg = "No document identifier provided"
      render :show
    end
  end

end
