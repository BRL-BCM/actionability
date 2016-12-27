
module GenboreeAcTemplaters
  class Stg1RuleoutReportTemplater < AbstractTemplater
    TOP_LEVEL_TEMPLATES = {
      :doc => :stg1RuleOutRpt,
      :ref => nil
    }

    def initialize(modelHash, opts={})
      super(:stg1RuleOutRpt, modelHash, opts)
    end

    def refsHtml(refDocs)
      raise NotImplementedError
    end
  end
end
