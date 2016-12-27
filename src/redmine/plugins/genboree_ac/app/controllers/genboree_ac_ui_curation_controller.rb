
#require 'plugins/genboree_ac/app/helpers/genboreeAc_perm_helper'
# Redmine - project management software
# Copyright (C) 2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.



# The initial version renders Raw web Content as-is, WITHOUT the base
#   Redmine layout. However, we keep around some aspects related to Redmine's
#   layout because we may want to add the ability, in the future, of inlining
#   raw content onto a Redmine-wrapped page.
# * How to indicate this is desired "view" of Raw Content may be tricky.
# ** Possibly protected extension/:format like ".wrap" or ".inline".
# ** But then how to deal best with all the href/src/etc to related raw content (e.g. inline images)?
# ** Perhaps just make sister-plugin called "wrappedContent" and separate /projects/{:id}/rawcontent/
#      from /projects/{:id}/wrapContent/ completely. Then don't have to worry about relative links
#      and inline-page assets (shouldn't be issue though, just relative links) having correct path/params.
# *** Or perhaps just have this support rawcontent and wrappedContent and use that as a switch for layout=>true/false
# ** Regardless, mixing these two approaches to Content is a no-go since in both approaches, page-editing
#     is required to get links to the *other* Content mode.
class GenboreeAcUiCurationController < ApplicationController
  class GenboreeAcUiCurationControllerError < StandardError; end
  include GenboreeAcHelper
  include GenboreeAcHelper::PermHelper
  unloadable
  layout 'ac_bootstrap_extensive_hdr_ftr' 
  before_filter :find_project, :authorize
  before_filter :require_admin, :only => [ :create ]

  # ------------------------------------------------------------------
  # Possibly helps with API support and certainly API-KEY type authentication.
  # ------------------------------------------------------------------
  skip_before_filter :check_if_login_required
  skip_before_filter :verify_authenticity_token

  accept_api_auth :index, :create, :delete


  def show()
    # @todo dynamically set @removeLayout from database record
    @docIdentifier = params['doc'] || ''
    @genboreeAc = GenboreeAc.find_by_project_id(Project.find(@project))
    @userPermsJS = pluginUserPerms(:genboree_ac, @project, User.current, :as => :javascript)
    @litSearchSourceJSON = getLitSearchSourceHashJSON()
    $stderr.puts "@litSearchSourceJSON:\n#{@litSearchSourceJSON.inspect}"
    #$stderr.puts "DEBUG - #{__method__}() => admin? #{User.current.admin?().inspect} ;;; User:\n\n#{User.current.inspect}"
    render :show
  rescue GenboreeAcUiCurationControllerError => e
    $stderr.puts "ERROR - #{__method__}() => Exception! #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}\n\n"
    render_error e.message
  end

  

 

  # ------------------------------------------------------------------
  # PRIVATE HELPERS
  # ------------------------------------------------------------------

  private

  
end
