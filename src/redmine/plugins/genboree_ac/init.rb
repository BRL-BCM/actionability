#require 'redmine'
#require 'genboree_ac'
#require 'brl/util/util'

require 'uri'
require 'yaml'
require 'json'
require 'mysql2'
require 'em-http-request'
require 'brl/util/util'
require 'brl/db/dbrc'
require 'brl/rest/apiCaller'
require 'brl/cache/helpers/dnsCacheHelper'
require 'brl/cache/helpers/domainAliasCacheHelper'
require 'brl/genboree/kb/kbDoc'
require 'brl/genboree/kb/propSelector'
require 'brl/genboree/kb/producers/abstractTemplateProducer'

require_dependency 'genboree_ac/hooks'

# Require our patches to built-in Redmine controllers
#require 'projects_controller_patch'
Redmine::Plugin.register :genboree_ac do
  name 'Genboree Actionability Curation plugin'
  author 'Sameer Paithankar'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  settings  :partial => 'settings/genboree_ac',
            :default =>
            {
              'path'                  => '/var/genboree_ac/{PROJECT}', # ? doesn't seem to be used or at least not correctly
              'index'                 => 'index.html',
              #'extensions'  => ".*",
              'menu'                  => 'Actionability Curation'
              #'maxEmbedFileSize' => (2 * 1024 * 1024)
            }
  project_module(:genboree_ac) {
    # "VIEW/RETRIEVE" the various Sencha Assets
    permission :gbac_view_sencha, { :genboree_ac_sencha => [ :index, :show ] }
    # Who can view the ENTRY page?
    permission :gbac_view_entry, { :genboree_ac_ui_entry => [ :show] }
    # Who can view the doc versions page ?
    permission :gbac_view_doc_versions, { :genboree_ac_ui_doc_versions => [ :show] }
    # Who can view the docs status page
    permission :gbac_view_docs_status, { :genboree_ac_ui_docs_status => [ :show] }
    # Who can view the various VIEW/REPORT pages?
    permission :gbac_view_full_view, { :genboree_ac_ui_full_view => [ :show] }
    permission :gbac_view_stg1_rule_out_report, { :genboree_ac_ui_stg1_rule_out_report => [ :show ] }
    permission :gbac_view_stg2_summary_report, { :genboree_ac_ui_stg2_summary_report => [ :show ] }
    # Who can view the CURATION page? Just covers viewing/getting to the page, not specific activities on the page
    permission :gbac_view_curation, { :genboree_ac_ui_curation => [ :show] }
    # Who can view the inidividual sections/stages of the curation page
    permission :gbac_view_lit_search, { :genboree_ac_ui_curation => [ :show] }
    permission :gbac_view_stage1, { :genboree_ac_ui_curation => [ :show] }
    permission :gbac_view_stage2, { :genboree_ac_ui_curation => [ :show] }
    permission :gbac_view_scoring, { :genboree_ac_ui_curation => [ :show] }
    #permission :gbac_view_scoring_status, { :genboree_ac_ui_curation => [ :show] }
    # CURATION - SPECIFIC PERMISSIONS (checked in curation controller(s) and view(s))
      # Who can edit syndrome info
      permission :gbac_edit_syndrome_info, { :genboree_ac_ui_curation => [ :show] }
      # Who can set the overall document status
      permission :gbac_edit_doc_status_info, { :genboree_ac_ui_curation => [ :show] }
      # Who can 'release/retract' a document
      permission :gbac_edit_doc_release, { :genboree_ac_ui_curation => [ :show] }
      # Who can edit/fill-in the literature search content?
      permission :gbac_edit_lit_search, { :genboree_ac_ui_curation => [ :show] }    
      # Who can finalize the literature search?    
      permission :gbac_finalize_lit_search, { :genboree_ac_ui_curation => [ :show] }
      # Who can edit/fill-in the curation stage 1 survey?    
      permission :gbac_edit_stage1, { :genboree_ac_ui_curation => [ :show] }
      # Who is the approver of the stage1 section
      permission :gbac_edit_final_stage1, { :genboree_ac_ui_curation => [ :show] }
      # Who can finalize the curation stage 1 survey?    
      permission :gbac_finalize_stage1, { :genboree_ac_ui_curation => [ :show] }
      # Who can edit/fill-in the curation stage 2 content? 
      permission :gbac_edit_stage2, { :genboree_ac_ui_curation => [ :show] }
      # Who can finalize the curation stage 2 content?    
      permission :gbac_finalize_stage2, { :genboree_ac_ui_curation => [ :show] }
      # Who can edit/fill-in their own curation scoring ? 
      permission :gbac_edit_scoring, { :genboree_ac_ui_curation => [ :show] }
      # Who is the approver of the scoring section
      permission :gbac_edit_final_scores, { :genboree_ac_ui_curation => [ :show] }
      # Who can finalize their own curation scoring ? 
      permission :gbac_finalize_scoring, { :genboree_ac_ui_curation => [ :show] }
      # Who can rollback "completed" sections in the curation page?
      permission :gbac_rollback_completion, { :genboree_ac_ui_curation => [ :show] }
    # TMP / TEST permissions
      permission :gbac_test_put_delete, {
          :put_proto => [ :putGrp ],
          :delete_proto => [ :deleteGrp ]
      }
    # API - SPECIFIC PERMISSIONS (checked in API controller(s))
      # @todo Allow permission control on Anonymous access even when Project is NOT public (like in VBR; requires genboree_generic methods)
      # @todo But may need per-project control over whether to enable Anonymous API access. e.g. Yes for Release, but No [only private API] for Curation track.
      # @todo Make sure private works with Redmine API token based auth.
      # @todo Make sure can force https. Have nginx add an http header with original protocol; genboree_generic methods to examine and answer questions. Project settings to require (e.g. for private access via Redmine API token)
      permission :gbac_api_view_doc, { :genboree_ac_api_doc_summary => [ :full ] }
      permission :gbac_api_view_doc_summary, { :genboree_ac_api_doc_summary => [ :dispatcher ] }
      permission :gbac_api_view_doc_all_scores, { :genboree_ac_api_doc_summary => [ :all_scores ] }
  }
  menu :project_menu, :genboree_ac,
    {
      :controller => "genboree_ac_ui_docs_status",
      :action => "show"
    },
    :caption => Proc.new { Setting.plugin_genboree_ac['menu'] },
    :if      => Proc.new { !Setting.plugin_genboree_ac['menu'].blank? }
end
