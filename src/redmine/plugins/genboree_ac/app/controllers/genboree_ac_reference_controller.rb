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
    
  end
  
end