class GenboreeAcUiCurationSectionsController < ApplicationController
  def show()
    render :partial => 'genboree_ac_ui_curation_sections/sections', :layout => false
  end
  
end