
module GenboreeAcTemplaters
  class Stg2SummaryReportTemplater < AbstractTemplater
    TOP_LEVEL_TEMPLATES = {
      :doc => :stg2SummaryRpt,
      :ref => :acRefMedium
    }

    def initialize(modelHash, opts={})
      super(:stg2SummaryRpt, modelHash, opts)
    end

    def makeRefsHtml(refDocs)
      raise NotImplementedError
    end
  end
end
