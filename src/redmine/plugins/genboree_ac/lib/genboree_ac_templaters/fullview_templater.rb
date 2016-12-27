
module GenboreeAcTemplaters
  class FullviewTemplater < AbstractTemplater
    TOP_LEVEL_TEMPLATES = {
      :doc => :acDoc,
      :ref => :acRefMedium
    }

    def initialize(modelHash, opts)
      super(:fullView, modelHash, opts)
    end
  end
end

