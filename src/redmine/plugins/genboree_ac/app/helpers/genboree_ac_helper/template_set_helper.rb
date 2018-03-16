module GenboreeAcHelper
  # Helper method for Controllers (mainly) to include so working with TemplateSets is
  #   (a) a bit more convenient
  #   (b) not duplicating code in dev (or team...think beyond your personal narrow focus) but rather reusing
  #   (c) contained not smeared everywhere through redundatnt code and is thus easily findable and maintained
  #   (d) caching--not loading and extracting info everywhere
  #   The module will provide some basic accessors but dev code should not use those directly. Rather
  #     USE/WRITE a method here that employs the data saved into those accessors. SEE ABOVE.
  #   Assumes @project is available, probably via find_project, although this can be overridden.
  #   Assumes @settingsRec is available, as per find_settings from genboree_generic
  #   Init the template sets via {}#loadTemplateSetsDoc} before employing other methods.
  module TemplateSetHelper

    HELPER_METHODS = [
      :loadTemplateSetsDoc,
      :currTemplateSet,
      :newestTemplateSet,
      :firstTemplateSet,
      :oldestTemplateSet,
      :minAcDocVer,
      :templateSetByAcVer,
      :templateSetDir,
      :templateGroupDir,
      :templateSets
    ]
    MEMOIZED_INSTANCE_METHODS = [
      :templateSetDir,
      :templateGroupDir
    ]
    METHOD_INFO = {
      :loadTemplateSetsDoc => {
        :opts => { :notifyWebServer => true  },
        :rsrcPathTpl => '/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true'
      },
      :loadTemplateSetAndRender => {
        :opts => { :notifyWebServer => true  },
        :rsrcPathTpl => '/REST/v1/grp/{grp}/kb/{kb}/coll/{coll}/docs?detailed=true'
      },
      :templateSets => {},
      :firstTemplateSet => {},
      :oldestTemplateSet => {},
      :currTemplateSet => {},
      :newestTemplateSet => {},
      :minAcDocVer => {},
      :templateSetByAcVer => {}
    }

    def self.included(includingClass)
      # To have controller methods available in Views, Rails requires them to be declared as
      #   helper_methods. Of course wherever they get included needs to also have the helper_method()
      #   method. Controllers and AbstractController::Helpers do, and can be used to expose
      #   the methods in the subordinate Views. This should handle other cases appropriately.
      if( includingClass.respond_to?( :helper_method) )
        GenboreeAcHelper::TemplateSetHelper::HELPER_METHODS.each { |method|
          includingClass.helper_method method
        }
      end

      # ----------------------------------------------------------------
      # Also arrange for including class to memoize the appropriate methods (don't want module doing it, won't work as expected)
      includingClass.extend Memoist
      # Arrange for including class to configure memoization of all now-defined methods
      GenboreeAcHelper::TemplateSetHelper::MEMOIZED_INSTANCE_METHODS.each { |method| includingClass.memoize method }
    end

    # @return [BRL::Genboree::KB::KbDoc] DO NOT USE DIRECTLY. WRITE METHODS. The template sets doc from the KB.
    attr_accessor :templateSetsDoc
    # @return [Array<BRL::Genboree::KB::KbDoc>] DO NOT USE DIRECTLY. WRITE METHODS. The template sets KbDocs.
    attr_accessor :templateSets
    # @return [Fixnum] DO NOT USE DIRECTLY. WRITE METHODS. The minimum AC doc version the template sets can handle. Before this, template sets were not used. Acts a cache so not digging through docs over and over.
    attr_accessor :templateSetsMinAcDocVer
    # @return [BRL::Genboree::KB::KbDoc] DO NOT USE DIRECTLY. WRITE METHODS. The first/oldest/rank=0 template set.
    attr_accessor :templateSetsFirstSet
    # Additional accessors made JIT within loadTemplateSetAndRender() but need to be here to see in Views
    #   (Views don't get access to instance variables populated JITwithin modules)
    attr_accessor :templateSet, :templateSetDir

    # INIT. Load the template sets KbDoc from the indicated collection, do some basic extraction/processing, and
    #   save/cache as accessorts.
    # @note Use this before other TemplateSetHelper methods.
    # @note ASYNC/Callback based. You need a callback.
    # @note Assumes @settingsRec is available, as from find_settings from genboree_generic (@todo AC uses a deprecated approach...fix that to use genboree_generic find_settings)
    # @param [Hash] env A proper Rack env Hash, with 'async.callback' available for extreme errors and :currRmUser
    # @param [Project] proj The relevant Redmine project employing this plugin.
    # @param [Hash{Symbol,Object}] opts Key options and rare overrides.
    # @yieldParam [Hash{Symbol,Object}] results The callback is supplied a Hash with either the :obj or :err keys.
    #   @option results [BRL::Genboree::KB::KbDoc] :obj If successful, the callback is given a Hash with the template sets
    #     KbDoc available at :obj. We MAY CHANGE THIS VALUE TO SIMPLY BE true IF DEV CODE INAPPROPRIATE WORKS WITH THE KbDoc
    #     DIRECTLY.
    #   @option results [Exception] :err Else, if an error is encountered, an Exception value is available at :err.
    #     This should be used for sensible success/fail flow-of-control.
    # @return [true, Exception] As usual you should in your synchronous flow that this method returned immediately with
    #   true and not @nil@ nor @Exceptions@; if true, then the registration of the async work including your callback
    #   succeeded and is pushed onto the EM event queue.
    def loadTemplateSetsDoc( env, proj=@project, opts=METHOD_INFO[__method__][:opts], &callback )
      retVal = nil # Should be true if async request etc all prepped ok
      # options
      methodInfo = METHOD_INFO[__method__]
      opts = methodInfo[:opts].merge(opts)
      cb = (block_given? ? Proc.new : callback)
      raise ArgumentError, "ERROR: the proj argument must be a valid Redmine Project object" unless( proj.is_a?(Project) )
      if( cb )
        # Build the base/top-level template sets dir
        @templateSetsDir = Rails.root.join('plugins', 'genboree_ac', 'templates')
        fieldMap = { :grp => @settingsRec.gbGroup, :kb => @settingsRec.gbKb, :coll => @settingsRec.templateSetsColl }
        doThrowAsync = opts[:notifyWebServer]
        # Create async api requester and register our callabck
        apiReq = GbApi::JsonAsyncApiRequester.new(env, @settingsRec.gbHost, proj)
        apiReq.notifyWebServer = doThrowAsync
        apiReq.bodyFinish {
          begin
            if( apiReq.respBody.is_a?(Exception) ) # req failed in some way
              cb.call( :err => apiReq.respBody )
            else # so far so good
              if(apiReq.respStatus >= 200 and apiReq.respStatus < 400)
                if( apiReq.apiDataObj.is_a?(Array) and apiReq.apiDataObj.size == 1 )
                  @templateSetsDoc = BRL::Genboree::KB::KbDoc.new( apiReq.apiDataObj.first )
                  @templateSets = @templateSetsDoc.getPropItems('TemplateSetDocID.TemplateSets')
                  # Make each templateSet a KbDoc so dev code doesn't have to do this (it's lightweight delegate)
                  @templateSets.map! { |ts| tsDoc = BRL::Genboree::KB::KbDoc.new(ts) }
                  cb.call( { :obj => @templateSetsDoc } )
                else # No doc contents??
                  cb.call( :obj => nil )
                end
              else
                msg = "HTTP error code #{apiReq.respStatus.inspect} returned when retrieving document via #{apiReq.fullApiUrl.inspect}. It is possible that you do not have access to this document or this collection/document does not exist."
                err = IOError.new("ERROR: #{msg}")
                $stderr.debugPuts(__FILE__, __method__, 'ERROR', msg)
                cb.call( { :err => err} )
              end
            end
          rescue => err
            $stderr.debugPuts(__FILE__, __method__, 'ERROR', "#{err.message.inspect}\n  Error Class: #{err.class}\n  Error trace:\n\n#{err.backtrace.join("\n")}\n\n")
            cb.call( { :err => err } )
          end
        }
        # Start async api call (put on event queue)
        apiReq.get( methodInfo[:rsrcPathTpl], fieldMap )
        retVal = true
      else
        cb.call( { :err => ArgumentError.new( "ERROR: missing callback block or Proc for this non-blocking method." ) } )
      end
      return retVal
    end

    # Get the dir where this templateSet lives (will have 1+ templateGroups as subdirs below it)
    # @note This method is memoized.
    # @note Use the {#loadTemplateSetsDoc} initiator first (or after #{loadTemplateSetAndRender})
    # @note This is NOT async. Just call it.
    # @param [String, BRL::Genboree::KB::KbDoc] templateSet The TemplateSet item (as KbDoc) or its ID string.
    # @return [String] The directory where the TemplateSet lives, as a String.
    def templateSetDir( templateSet )
      retVal = nil
      templateSet = BRL::Genboree::KB::KbDoc.new( templateSet ) if( templateSet.is_a?(Hash) )
      if( templateSet.is_a?( BRL::Genboree::KB::KbDoc) ) # then need to dig out the templateSet ID
        if( templateSet.exists?('TemplateSet') )
          templateSet = templateSet.getPropVal('TemplateSet')
        end
      end

      if( templateSet.is_a?(String) )
        retVal = "#{@templateSetsDir}/#{templateSet}"
      else # Error, should be the templateSet ID by now, regardless of argument type
        raise ArgumentError, "ERROR: The templateSet arg is not a String nor a valid TemplateSet item KbDoc. It is: #{templateSet.inspect}"
      end
        # "{templateSetsDir}/{templateSetID}/{templateGroup}"

      return retVal
    end

    # Get the dir where the desired TemplateGroup (named bunch of templates for rendering a particular view/report) lives
    #   under the indicated TemplateSet.
    # @note This method is memoized.
    # @note Use the {#loadTemplateSetsDoc} initiator first (or after #{loadTemplateSetAndRender})
    # @note This is NOT async. Just call it.
    # @param [Symbol, String] templateGroup The template group, a named bunch of template files for a particular view/report.
    # @param [String, BRL::Genboree::KB::KbDoc] templateSet The TemplateSet item (as KbDoc) or its ID string.
    # @return [String] The directory where the TemplateSet lives, as a String.
    def templateGroupDir( templateGroup, templateSet )
      retVal = nil
      tsDir = templateSetDir( templateSet )
      if( tsDir )
        retVal = "#{tsDir}/#{templateGroup}"
      end
      return retVal
    end

    # Get the template sets as an array of KbDocs. Cache.
    # @note This method should be used rather than the accessor.
    # @note Use the {#loadTemplateSetsDoc} initiator first (or after #{loadTemplateSetAndRender})
    # @note This is NOT async. Just call it.
    # @param [Hash{Symbol,Object}] opts Optional.
    # @return [Array<BRL::Genboree::KB::KbDoc>] The template sets definitions.
    def templateSets( opts=METHOD_INFO[__method__][:opts] )
      if( @templateSets.nil? )
        if( @templateSetsDoc ) # Should be if loadTemplateDoc() done first or if have in some other way
          @templateSets = @templateSetsDoc.getPropItems('TemplateSetDocID.TemplateSets')
          # Make each templateSet a KbDoc so dev code doesn't have to do this (it's lightweight delegate)
          @templateSets.map! { |ts| BRL::Genboree::KB::KbDoc.new(ts) }
        else
          $stderr.debugPuts(__FILE__, __method__, 'WARNING - DEV BUG?', "You are trying to get templateSets info, but doesn't seem like you arranged to have template sets KbDoc loaded [async] via loadTimeplateSetsDoc() async call or similar. Will never find your template file(s) without that key info available.")
          @templateSets = nil
        end
      end

      return @templateSets
    end

    # Get the first/oldest template set. This is the Rank=0 template set. Cache.
    # @note Use the {#loadTemplateSetsDoc} initiator first (or after #{loadTemplateSetAndRender})
    # @note This is NOT async. Just call it.
    # @param [Hash{Symbol,Object}] opts Optional.
    # @return [BRL::Genboree::KB::KbDoc] The definition/metadata for the first/oldest template set.
    def firstTemplateSet( opts=METHOD_INFO[__method__][:opts]  )
      if( @templateSetsFirstSet.nil? )
        # Get the template sets--method preferred over accessor/cache
        tplSets = templateSets( opts )
        if( tplSets )
          # Regardless of whether we dug it out or used cached version, find MinAcDocVer
          @templateSetsFirstSet = tplSets.find { |tsDoc|
            (tsDoc.getPropVal('TemplateSet.Rank') == 0)
          }
        else
          @templateSetsFirstSet = nil
        end
      end

      return @templateSetsFirstSet
    end
    alias_method :oldestTemplateSet, :firstTemplateSet


    # Get the current/newest template set. This is the template set for which MaxAcDocVer is missing. Cache.
    # @note Use the {#loadTemplateSetsDoc} initiator first (or after #{loadTemplateSetAndRender})
    # @note This is NOT async. Just call it.
    # @param [Hash{Symbol,Object}] opts Optional.
    # @return [BRL::Genboree::KB::KbDoc] The definition/metadata for the current/newest template set.
    def currTemplateSet( opts=METHOD_INFO[__method__][:opts]  )
      if( @templateSetsCurrSet.nil? )
        # Get the template sets--method preferred over accessor/cache
        tplSets = templateSets( opts )
        if( tplSets )
          # Regardless of whether we dug it out or used cached version, find doc with missing MaxAcDocVer (i.e. the open-ended range)
          @templateSetsCurrSet = tplSets.find { |tsDoc|
            ( !tsDoc.exists?('TemplateSet.MaxAcDocVer') )
          }
        else
          @templateSetsCurrSet = nil
        end
      end

      return @templateSetsCurrSet
    end
    alias_method :newestTemplateSet, :currTemplateSet

    # Get the minimum AC doc version that the TemplateSets apply to. Doc versions before this minimum are NOT
    #   covered by TemplateSets (pre-date template sets) and the historical versions cannot be rendered.
    # @note Use the {#loadTemplateSetsDoc} initiator first (or after #{loadTemplateSetAndRender})
    # @note This is NOT async. Just call it.
    # @param [Hash{Symbol,Object}] opts Optional.
    # @return [Fixnum] The minimum AC doc version for which TemplateSets are relevant.
    def minAcDocVer( opts=METHOD_INFO[__method__][:opts] )
      if( @templateSetsMinAcDocVer.nil? )
        # Get the first/oldest (Rank=0) template set
        rank0TemplateSet = firstTemplateSet( opts )
        @templateSetsMinAcDocVer = ( rank0TemplateSet ? ( rank0TemplateSet.getPropVal('TemplateSet.MinAcDocVer').to_i ) : nil ) rescue nil
      end

      return @templateSetsMinAcDocVer
    end

    # Find the appropriate TemplateSet, if any, given an AC doc's version.
    # @note Use the {#loadTemplateSetsDoc} initiator first (or after #{loadTemplateSetAndRender})
    # @note This is NOT async. Just call it.
    # @param [Fixnum,nil] acDocVersion The AC doc version for which you need the appropriate TemplateSet.
    #   If nil then will assume you're using the default version...the "HEAD" or most recent version available.
    #   In which case the most recent / current TemplateSet also applies.
    # @param [Hash{Symbol,Object}] opts Optional.
    # @return [BRL::Genboree::KB::KbDoc,nil] The appropriate TemplateSet info or nil if no appropriate template set found.
    def templateSetByAcVer( acDocVersion, opts=METHOD_INFO[__method__][:opts]  )
      retVal = nil
      if( acDocVersion.nil? ) # Then you are working with the "HEAD" or most-recent version of the doc.
        # Thus, also use the "HEAD" or most-recent TemplateSet as well
        retVal = currTemplateSet()
      else
        acDocVersion = acDocVersion.to_i
        # Get the template sets--method preferred over accessor/cache
        tplSets = templateSets( opts )
        if( tplSets )
          tplSet = tplSets.find { |tsDoc|
            # Min AC Doc version for this set
            minAcVer = tsDoc.getPropVal('TemplateSet.MinAcDocVer')
            if( acDocVersion >= minAcVer ) # Then this tpl may be appropriate. Need to check max
              # Max AC Doc version for this set (missing == infinity ; i.e. the head/current TemplateSet )
              maxAcVer = ( tsDoc.exists?('TemplateSet.MaxAcDocVer') ? tsDoc.getPropVal('TemplateSet.MaxAcDocVer') : nil )
              if( maxAcVer )
                if( acDocVersion <= maxAcVer ) # Version range fully closed and acDocVersion falls within, we're done.
                  rv = true
                else # Version range fully closed and acDocVersion doesn't fall within
                  rv = false
                end
              else # no MaxAcDocVer, range is open ended and acDocVersion falls within, we're done, the head/current TemplateSet matches.
                rv = true
              end
            else # acDocVersion smaller than minimum for this template set, keep looking
              rv = false
            end
            rv
          }
          retVal = tplSet
        end
      end

      return retVal
    end

    # Weakly-generic. But common pattern for all report controllers. This method is tighly tied to assumptions
    #   about how reports are generated by rendering retrieved @kbDoc and how error messages
    #   are rendered to the user by setting non-nil @viewMsg. The method will set a number of additional instance variables
    #   useful (and TYPICAL) within the rendering code, especially for use with code that uses
    #   BRL::Genboree::KB::Producers::AbstractTemplateProducer. It will load the appropriate TemplateSet info for a given
    #   AC doc version, extract and populate key instance variables useful for rendering via AbstractTemplateProducer,
    #   and then render by calling callback.
    # @note Typically the callback would have something like just "renderPage(:show)" and the View would use
    #   the instance variables to arrange rendering of some KbDoc(s) via the {BRL::Genboree::KB::Producers::AbstractTemplateProducer}.
    # @note If @kbDoc is nil or @viewMsg is NON-nil, because you have already noted some issue, the processing is skipped
    #   and it will jump right to your callback. This way you don't have add any conditional flow-of-control to avoid this method when
    #   prior code noted a problem (e.g. getting @kbDoc perhaps)
    # @note Additional instance variable made available hereafter and in any View are:
    #   "@acDocVersion"   - from the acDocVersion argument
    #   "@templateSet"    - the appropriate template set item
    #   "@templateSetDir" - the dir where the TemplateSet can be found ; it will have sub-dirs for each template-group
    #   "@kbDoc"          - presumably you already set this, but it will be forced to @nil@ if there is some issue
    #   "@viewMsg"        - when @kbDoc if forced to nil, this will have some information message String with info about the basic problem
    # @note No yieldparam to your callback. See above.
    # @param [Hash] env A proper Rack env Hash, with 'async.callback' available for extreme errors and :currRmUser
    # @param [Project] proj The relevant Redmine project employing this plugin.
    # @param [Hash{Symbol,Object}] opts Key options and rare overrides.
    # @return [true, Exception] As usual you should in your synchronous flow that this method returned immediately with
    #   true and not @nil@ nor @Exceptions@; if true, then the registration of the async work including your callback
    #   succeeded and is pushed onto the EM event queue.
    def loadTemplateSetAndRender( env, acDocVersion, proj=@project, opts=METHOD_INFO[__method__][:opts], &callback )
      retVal = nil # Should be true if async request etc all prepped ok
      # options
      methodInfo = METHOD_INFO[__method__]
      opts = methodInfo[:opts].merge(opts)
      cb = (block_given? ? Proc.new : callback)
      raise ArgumentError, "ERROR: the proj argument must be a valid Redmine Project object" unless( proj.is_a?(Project) )
      if( cb )
        @acDocVersion = acDocVersion
        loadTemplateSetsDoc( env, proj, opts ) { |result|
          if( !@kbDoc.nil? and @viewMsg.nil? ) # then no problems from previous code, can proceed
            if( result.is_a?(Hash) and !result.key?(:err) and result[:obj].is_a?(BRL::Genboree::KB::KbDoc) )
              #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "@acDocVersion = #{@acDocVersion.inspect} (from version param: #{params['version'].inspect})")
              # Get appropriate TemplateSet info. Make sure available to pass to View
              @templateSet = templateSetByAcVer( @acDocVersion )
              #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "@templateSet to use:\n\n#{JSON.pretty_generate(@templateSet) rescue @templateSet}\n\n")
              @templateSetDir = templateSetDir( @templateSet )
              #$stderr.debugPuts(__FILE__, __method__, 'DEBUG', "@templateSetDir where template-group subdirs can be found: #{@templateSetDir.inspect}")
              unless( @templateSet )
                @kbDoc = nil
                @viewMsg = "The version provided for the actionability doc (#{version.inspect}) is either invalid, or the TemplateSets metadata on the server is corrupt. "
              end
            else # Couldn't even retrieve TemplateSets info.
              @kbDoc = nil
              @viewMsg = "#{@lastApiReqErrText} Couldn't get the information about the GenboreeAc plugin TemplateSets available at this Redmine instance. Unexpected return when loading the information:\n\n#{JSON.pretty_generate(results) rescue results.inspect}\n\n"
            end
          end

          # With the set-up above, call the callback which should be a render-page type statement that uses the above instance variables
          cb.call()
        }
        retVal = true
      else
        raise ArgumentError, "ERROR: missing callback block or Proc for this non-blocking method."
      end
      return retVal
    end
  end
end