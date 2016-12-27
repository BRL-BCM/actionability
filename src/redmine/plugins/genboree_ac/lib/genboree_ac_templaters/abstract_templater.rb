require 'brl/genboree/kb/producers/abstractTemplateProducer'

module GenboreeAcTemplaters
  class AbstractTemplater
    TOP_LEVEL_TEMPLATES = {
      :doc => :acDoc,
      :ref => :acRefMedium
    }

    attr_reader :docProducer, :refsProducer

    def initialize(templateSet, modelHash, opts)
      @templateSet, @modelHash = templateSet, modelHash
      # If want to expose this in Redmine UI, it's a Redmine-wide setting for the genboree_ac plugin, not a project-specific one
      defaultPluginSettings = Redmine::Plugin.find('genboree_ac').settings[:default]
      tplPath = defaultPluginSettings[:producerTemplatesPaths][@templateSet].to_s
      optsBase = { :templateDir => tplPath, :relaxedRootValidation => true }
      @opts = optsBase.merge(opts)
      @docProducer = @refsProducer = nil
    end

    def docHtml(kbDoc)
      if(@docProducer)
        @docProducer.kbDoc = kbDoc
      else
        docProducer(kbDoc)
      end
      @docProducer.render(self.class::TOP_LEVEL_TEMPLATES[:doc])
    end

    def refsHtml(refDocs)
      refsProducer() unless(@refsProducer)
      refHtmls = []
      refDocs.each { |refDoc|
        @refsProducer.kbDoc = refDoc
        @refsProducer.opts[:count] += 1
        begin
          refHtml = @refsProducer.render(self.class::TOP_LEVEL_TEMPLATES[:ref])
          refHtmls << refHtml
        rescue => err
          $stderr.debugPuts(__FILE__, __method__, "ERROR", "Failed to render reference doc.\n  Error class: #{err.class}\n  Error msg: #{err.message.inspect}\n  Error trace:\n#{err.backtrace.join("\n")}\n\n")
        end
      }
      retVal = refHtmls.join("\n")
      return retVal
    end

    def docProducer(kbDoc)
      docModel = @modelHash[:docModel]
      # Make the docProducer
      @docProducer =  BRL::Genboree::KB::Producers::AbstractTemplateProducer.new( docModel, kbDoc, @opts )
      @docProducer.skipValidation = true # just retrieved model & doc from collection
      return @docProducer
    end

    def refsProducer()
      refModel = @modelHash[:refModel]
      # Make the refsProducer
      refOpts = @opts.deep_clone
      refOpts[:count] = 0
      @refsProducer = BRL::Genboree::KB::Producers::AbstractTemplateProducer.new( refModel, nil, refOpts )
      @refsProducer.skipValidation = true # just retrieved model & doc from collection
      return @refsProducer
    end
  end
end

