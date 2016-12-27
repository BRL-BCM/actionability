#!/usr/bin/env ruby
require 'escape_utils'
require 'uri_template'
require 'brl/util/util'
require 'brl/extensions/bson'
require 'brl/genboree/tools/toolConf'
require 'brl/genboree/rest/data/entity'
require 'brl/genboree/kb/kbDoc'

module BRL ; module Genboree ; module REST ; module Extensions ; module ClingenActionability ; module Data

  # WorkbenchJobEntity - Representation of a job submitted by the workbench
  #
  # Common Interface Methods:
  # - #to_json, #to_yaml, #to_xml             -- default implementations from parent class
  # - AbstractEntity.from_json, AbstractEntity.from_yaml, AbstractEntity.from_xml       -- default implementations from parent class
  # - #json_create, #getFormatableDataStruct  -- OVERRIDDEN
  class ActionabilityLookupDocEntity < BRL::Genboree::REST::Data::AbstractEntity
    # What formats are supported, using the conventional +Symbols+. Subclasses may or may not override this.
    FORMATS = [ :JSON, :JSON_PRETTY, :YAML ]
    # A +Symbol+ naming the resource with a code-friendly (ok, XML tag-name friendly) name. This is currently used in
    # generating XML for _lists_...they will be lists of tags of this type (XML makes it hard to express certain natural things easily...)
    RESOURCE_TYPE = :ActionabilityLookupDoc

    # @return [String] The key for the reference url (when connect=yes)
    # @todo remove this and use JSON-LD @ref approach
    REFS_KEY = "#{RESOURCE_TYPE}_#{FORMATS.join('.')}"

    # Any basic name-value type fields; i.e. where the value is not a complex data structure but rather some text or a number.
    # Framework will do some automatic processing and presentation of those for you. Subclasses will override this, obviously.
    SIMPLE_FIELD_NAMES = [ 'Id', 'Url', 'ReportUrl' ]

    # Class specific constants
    URL_TEMPLATE = URITemplate.new('http://{actionabilityRedmineHost}/{redmineMount}/projects/{redmineProject}/genboree_ac/ui/fullview?doc={docId}')
    REPORT_URL_TEMPLATE = URITemplate.new('http://{actionabilityRedmineHost}/{redmineMount}/projects/{redmineProject}/genboree_ac/ui/fullview?pdf={docId}')
    KBDOC_OPTS = { :nilGetOnPathError => true }

    # @return [BRL::Genboree::KB::KbDoc] The GenboreeKB document
    attr_accessor :doc
    attr_accessor :versionDoc
    attr_accessor :opts
    attr_accessor :apiExtConf

    # CONSTRUCTOR.
    # @param [Boolean] doRefs NOT SUPPORTED. FOR INTERFACE UNIFORMITY ONLY. Always @false@.
    # @param [BRL::Genboree::KB::KbDoc] doc The Genboree KB document to be represented.
    def initialize(doRefs=false, doc={}, versionDoc={}, apiExtConf={})
      super(false) # doRefs argument will be ignored
      @opts = opts
      @apiExtConf = apiExtConf
      self.update(doc, versionDoc)
    end

    # GENBOREE INTERFACE. Delegation-compliant is_a? called "acts_as?()".
    #   Override in sub-classes if the structured data representation is not a Hash or hash-like.
    #   Most entities do use Hash-like structured data representations (except lists, which indeed
    #   override this method, as you can find out for {AbstractEntityList} below).
    def acts_as?(aClass)
      return @doc.acts_as?(aClass)
    end

    # REUSE INSTANCE. Update this instance with new data; supports reuse of instances rather than always making new objects
    # @param [BRL::Genboree::KB::KbDoc] doc The Genboree KB document to be represented.
    # @return [ BRL::Genboree::KB::KbDoc] The Genboree KB document to be represented.
    def update(doc={}, versionDoc={})
      @doc = doc.deep_clone
      @doc = BRL::Genboree::KB::KbDoc.new(@doc) unless(@doc.is_a?(BRL::Genboree::KB::KbDoc))
      @doc.nilGetOnPathError = true
      @versionDoc = versionDoc.deep_clone
      @versionDoc = BRL::Genboree::KB::KbDoc.new(@versionDoc) unless(@versionDoc.is_a?(BRL::Genboree::KB::KbDoc))
      @versionDoc.nilGetOnPathError = true
    end

    # @api RestDataEntity
    # GENBOREE INTERFACE. Subclasses inherit; override for subclasses that generate
    # complex data representations mainly for speed (i.e. to avoid the reflection methods).
    # Inherited version works by using SIMPLE_FIELD_NAMES and reflection methods; even if you
    # just need the stuff in SIMPLE_FIELD_NAMES and don't have fields with complex data structures
    # in the representation, overriding to NOT use the reflection stuff will be faster [a little].
    #
    # Get a {Hash} or {Array} that represents this entity.
    # Generally used to convert to some String format for serialization. Especially to JSON.
    # @note Must ONLY use Ruby primitives (String, Fixnum, Float, booleans) or
    #   basic Ruby collections (Hash, Array). No custom classes.
    # @param [Boolean] wrap Indicating whether the standard Genboree wrapper should be used to
    #   contain the representation or not. Generally true, except when the representation is
    #   within a parent representation [which is likely wrapped].
    # @return [Hash,Array] representing this entity (or collection of entities)
    #   wrapped in the standardized Genboree wrapper, if appropriate.
    def toStructuredData(wrap=@doWrap)
      # Extract data from @doc using paths
      docId = @doc.getRootPropVal()
      # Build Url
      url = URL_TEMPLATE.expand(
        :actionabilityRedmineHost => @apiExtConf['redmine']['host'],
        :redmineMount             => @apiExtConf['redmine']['mount'],
        :redmineProject           => @apiExtConf['redmine']['project'],
        :docId                    => docId
      )
      # Build report URL.
      # @todo Currently supposed to be blank. Later a link to PDF if we can get it working.
      # reportUrl = URL_TEMPLATE.expand(
      #   :actionabilityRedmineHost => @apiExtConf['redmine']['host'],
      #   :redmineMount             => @apiExtConf['redmine']['mount'],
      #   :redmineProject           => @apiExtConf['redmine']['project'],
      #   :docId                    => docId
      # )
      reportUrl = ''
      # Dates
      dates = { 'LastUpdated' => versionDoc.getPropVal('versionNum.timestamp').to_s }
      # Genes
      genes = [ ]
      geneItems = @doc.getPropItems('ActionabilityDocID.Genes') || [ ]
      geneItems.each { |geneItem|
        geneDoc = BRL::Genboree::KB::KbDoc.new(geneItem, KBDOC_OPTS)
        genes << {
          'Gene' => geneDoc.getRootPropVal(),
          'HGNCId' => geneDoc.getPropVal('Gene.HGNCId').to_s
        }
      }
      # Disease
      disease  = {
        'Label'     => @doc.getPropVal('ActionabilityDocID.Syndrome').to_s,
        'OMIMIds'   => [],
        'Outcomes'  => []
      }
      # - omimIds
      omimItems = @doc.getPropItems('ActionabilityDocID.Syndrome.OmimIDs') || [ ]
      omimItems.each { |omimItem|
        omimDoc = BRL::Genboree::KB::KbDoc.new(omimItem, KBDOC_OPTS)
        disease['OMIMIds'] << omimDoc.getRootPropVal()
      }
      # - outcomes
      finalScoreOutcomes = @doc.getPropItems('ActionabilityDocID.Score.Final Scores.Outcomes') || [ ]
      finalScoreOutcomes.each { |outcome|
        outcomeDoc = BRL::Genboree::KB::KbDoc.new(outcome, KBDOC_OPTS)
        outcomeRec = {
          'Outcome' => outcomeDoc.getRootPropVal().to_s,
          'Interventions' => [ ]
        }
        interventions = outcomeDoc.getPropItems('Outcome.Interventions') || [ ]
        interventions.each { |intervention|
          interventionDoc = BRL::Genboree::KB::KbDoc.new(intervention, KBDOC_OPTS)
          outcomeRec['Interventions'] << {
            'Intervention' => interventionDoc.getRootPropVal().to_s,
            'Score' => {
              'Severity'      => interventionDoc.getPropVal('Intervention.Severity').to_s,
              'Likelihood'    => interventionDoc.getPropVal('Intervention.Likelihood').to_s,
              'Effectiveness' => interventionDoc.getPropVal('Intervention.Effectiveness').to_s,
              'NatureOfIntervention' => interventionDoc.getPropVal('Intervention.NatureOfIntervention').to_s,
              'Total' => interventionDoc.getPropVal('Intervention.Overall Score').to_s
            }
          }
        }
        disease['Outcomes'] << outcomeRec
      }

      # Assemble structured data:
      data = {
        'Id'        => docId,
        'Url'       => url,
        'ReportUrl' => reportUrl,
        'Dates'     => dates,
        'Genes'     => genes,
        'Disease'   => disease
      }
      retVal = (wrap ? self.wrap(data) : data)
      return retVal
    end

    # GENBOREE INTERFACE. Get a +Hash+ or +Array+ that represents this entity.
    # - used by the default implementations of <tt>to_*()</tt> methods
    # - override in sub-classes
    # - this data structure will be used in the serialization implementations
    # @note May need to check and remove keys added by MongoDB like "_id" or similar.
    # @return [Hash,Array] A {Hash} or {Array} representing this entity (or collection of entities)
    #   wrapped in the standardized Genboree wrapper, if appropriate. _Entity class specific_
    def getFormatableDataStruct()
      structure = toStructuredData(false)
      retVal = self.wrap(structure)  # Wrap the data content in standard Genboree JSON envelope
      return retVal
    end
  end # class ActionabilityLookupDocEntity < BRL::Genboree::REST::Data::AbstractEntity

  class ActionabilityLookupDocEntityList < BRL::Genboree::REST::Data::EntityList
    # What formats are supported, using the conventional +Symbols+. Subclasses may or may not override this.
    FORMATS = [ :JSON, :JSON_PRETTY, :YAML ]
    # A +Symbol+ naming the resource with a code-friendly (ok, XML tag-name friendly) name. This is currently used in
    # generating XML for _lists_...they will be lists of tags of this type (XML makes it hard to express certain natural things easily...)
    RESOURCE_TYPE = :ActionabilityLookupDocList

    # @return [String] The key for the reference url (when connect=yes)
    # @todo remove this and use JSON-LD @ref approach
    REFS_KEY = "#{RESOURCE_TYPE}_#{FORMATS.join('.')}"

    # What kind of objects does this collection/list store?
    ELEMENT_CLASS = ActionabilityLookupDocEntity
    # Whether the values stored in @array are objects implementing toStructuredData() (constant to save reflection at runtime)
    ELEMENT_IMPLEMENTS_TOSTRUCTUREDDATA = ELEMENT_CLASS.method_defined?(:toStructuredData)

  end

end ; end ; end ; end ; end ; end # module BRL ; module Genboree ; module REST ; module Extensions ; module ClingenActionability ; module Data