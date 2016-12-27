require 'yaml'
require 'json'
require 'uri'
require 'brl/rest/apiCaller'
require 'brl/util/util'
include BRL::REST

class GenboreeAcReferenceController < ApplicationController
  include GenboreeAcHelper
  
  respond_to :json
  before_filter :find_project
  
  unloadable
  
  def show()
    addProjectIdToParams()
    $stderr.puts "params (show): #{params.inspect}"
    rsrcPath = "/REST/v1/grp/aa1/db/hg19db1/file/reference.json/data?"
    apiResult = apiGet(rsrcPath, {}, false)
    respond_with(apiResult[:respObj], :status => apiResult[:status])
  end
  
end