
# How do these routes affect sub-dirs? Not at all? What about "upload" ~sub-dir
# How do these routes affect .xml, .json API type representatons (they don't?)
RedmineApp::Application.routes.draw do
  #get '/projects/:id/genboree_ac/sencha(/*request_path(.:format))', :to => "genboree_ac_sencha#index", :as => :genboree_ac_sencha_index
  #get '/projects/:id/genboree_ac/sencha(/*request_path)', :to => "genboree_ac_sencha#index", :as => :genboree_ac_sencha_index
  ## Point sench-apps to the correct controller action
  #get '/projects/:id/genboree_ac/sencha-apps(/*request_path(.:format))', :to => "genboree_ac_sencha#index", :as => :genboree_ac_sencha_index
  #get '/projects/:id/genboree_ac/sencha-apps/(*request_path(.:format))', :to => redirect('/projects/%{id}/genboree_ac/sencha/sencha-apps/%{request_path}')
  #get '/projects/:id/genboree_ac/sencha/:path', :to => "genboree_ac_sencha#link", :as => :genboree_ac_sencha_link
  # --------
  # CURATION
  get '/projects/:id/genboree_ac/ui/curation', :to => "genboree_ac_ui_curation#show", :as => :genboree_ac_ui_curation_show
  get '/projects/:id/genboree_ac/data/references/show', :to => "genboree_ac_references#show", :as => :genboree_ac_references_show
  get '/projects/:id/genboree_ac/data/references/reference/show', :to => "genboree_ac_references#reference", :as => :genboree_ac_reference_show
  get '/projects/:id/genboree_ac/ui/curation/sectionContents', :to => "genboree_ac_section_contents#show", :as => :genboree_ac_section_contents_show
  get '/projects/:id/genboree_ac/data/doc/show', :to => "genboree_ac_doc#show", :as => :genboree_ac_doc_show
  get '/projects/:id/genboree_ac/data/doc/model', :to => "genboree_ac_doc#model", :as => :genboree_ac_doc_model
  get '/projects/:id/genboree_ac/data/doc/syndrome', :to => "genboree_ac_doc#syndrome", :as => :genboree_ac_doc_syndrome
  get '/projects/:id/genboree_ac/data/doc/refFile/download', :to => "genboree_ac_doc#downloadRefFile", :as => :genboree_ac_doc_downloadRefFile
  get '/projects/:id/genboree_ac/data/doc/fileMimeType', :to => "genboree_ac_doc#fileMimeType", :as => :genboree_ac_doc_fileMimeType
  get '/projects/:id/genboree_ac/data/doc/status', :to => "genboree_ac_doc#status", :as => :genboree_ac_doc_status
  get '/projects/:id/genboree_ac/data/doc/refFiles', :to => "genboree_ac_doc#refFiles", :as => :genboree_ac_doc_refFiles
  get '/projects/:id/genboree_ac/data/history/show', :to => "genboree_ac_history#show", :as => :genboree_ac_history_show
  get '/projects/:id/genboree_ac/data/history/diffOutcome', :to => "genboree_ac_history#diffOutcome", :as => :genboree_ac_history_diff_outcome
  get '/projects/:id/genboree_ac/data/history/diffBaseSection', :to => "genboree_ac_history#diffBaseSection", :as => :genboree_ac_history_diff_BaseSection
  post '/projects/:id/genboree_ac/data/references/reference/update', :to => "genboree_ac_references#update", :as => :genboree_ac_reference_update
  post '/projects/:id/genboree_ac/data/history/revertOutcome', :to => "genboree_ac_history#revertOutcome", :as => :genboree_ac_history_revert_outcome
  post '/projects/:id/genboree_ac/data/history/revertStage2BaseSection', :to => "genboree_ac_history#revertStage2BaseSection", :as => :genboree_ac_history_revert_stage2BaseSection
  post '/projects/:id/genboree_ac/data/stageOne/save', :to => "genboree_ac_stage_one#save", :as => :genboree_ac_stage_one_save
  post '/projects/:id/genboree_ac/data/doc/syndrome/save', :to => "genboree_ac_doc#saveSyndromeInfo", :as => :genboree_ac_doc_saveSyndromeInfo
  post '/projects/:id/genboree_ac/data/doc/status/save', :to => "genboree_ac_doc#saveStatusInfo", :as => :genboree_ac_doc_saveStatusInfo
  post '/projects/:id/genboree_ac/data/doc/genes/save', :to => "genboree_ac_doc#saveGenesInfo", :as => :genboree_ac_doc_saveGenesInfo
  post '/projects/:id/genboree_ac/data/stageOne/status/save', :to => "genboree_ac_stage_one#saveStatus", :as => :genboree_ac_stage_one_saveStatus
  post '/projects/:id/genboree_ac/data/stageTwo/saveOutcome', :to => "genboree_ac_stage_two#saveOutcome", :as => :genboree_ac_stage_two_saveOutcome
  post '/projects/:id/genboree_ac/data/stageTwo/saveCategory', :to => "genboree_ac_stage_two#saveCategory", :as => :genboree_ac_stage_two_saveCategory
  post '/projects/:id/genboree_ac/data/stageTwo/saveStatus', :to => "genboree_ac_stage_two#saveStatus", :as => :genboree_ac_stage_two_saveStatus
  post '/projects/:id/genboree_ac/data/stageTwo/remove', :to => "genboree_ac_stage_two#remove", :as => :genboree_ac_stage_two_remove
  post '/projects/:id/genboree_ac/data/score/saveScorerInfo', :to => "genboree_ac_score#saveScorerInfo", :as => :genboree_ac_scorer_saveScorerInfo
  post '/projects/:id/genboree_ac/data/score/saveUserStatus', :to => "genboree_ac_score#saveUserStatus", :as => :genboree_ac_scorer_saveUserStatus
  post '/projects/:id/genboree_ac/data/score/saveOverallStatus', :to => "genboree_ac_score#saveOverallStatus", :as => :genboree_ac_scorer_saveOverallStatus
  post '/projects/:id/genboree_ac/data/score/saveSummaryInfo', :to => "genboree_ac_score#saveSummaryInfo", :as => :genboree_ac_scorer_saveSummaryInfo
  post '/projects/:id/genboree_ac/data/score/saveAttendeeInfo', :to => "genboree_ac_score#saveAttendeeInfo", :as => :genboree_ac_scorer_saveAttendeeInfo
  post '/projects/:id/genboree_ac/data/litSearch/save', :to => "genboree_ac_lit_search#saveSourceInfo", :as => :genboree_ac_lit_search_saveSourceInfo
  post '/projects/:id/genboree_ac/data/litSearch/status/save', :to => "genboree_ac_lit_search#saveStatus", :as => :genboree_ac_lit_search_saveStatus
  post '/projects/:id/genboree_ac/data/litSearch/remove', :to => "genboree_ac_lit_search#remove", :as => :genboree_ac_lit_search_remove
  post '/projects/:id/genboree_ac/data/doc/reference/fileUpload', :to => "genboree_ac_doc#refFileUpload", :as => :genboree_ac_doc_refFileUpload
  post '/projects/:id/genboree_ac/data/doc/refFile/delete', :to => "genboree_ac_doc#refFileDelete", :as => :genboree_ac_doc_refFileDelete
   
  # --------
  # ENTRY
  get '/projects/:id/genboree_ac/ui', :to => "genboree_ac_ui_entry#show", :as => :genboree_ac_ui_entry_show
  get '/projects/:id/genboree_ac', :to => "genboree_ac_ui_entry#show", :as => :genboree_ac_ui_entry_show
  get '/projects/:id/genboree_ac/ui/entry', :to => "genboree_ac_ui_entry#show", :as => :genboree_ac_ui_entry_show
  get '/projects/:id/genboree_ac/data/docs/show', :to => "genboree_ac_entry#show", :as => :genboree_ac_docs_show
  get '/projects/:id/genboree_ac/data/docs/genes', :to => "genboree_ac_entry#genes", :as => :genboree_ac_docs_genes
  get '/projects/:id/genboree_ac/data/docs/actionDocs', :to => "genboree_ac_entry#actionDocs", :as => :genboree_ac_docs_actionDocs
  post '/projects/:id/genboree_ac/data/doc/actionDocSave', :to => "genboree_ac_entry#save", :as => :genboree_ac_entry_save
  # --------
  # FULL VIEW
  get '/projects/:id/genboree_ac/ui/fullview', :to => "genboree_ac_ui_full_view#show", :as => :genboree_ac_ui_full_view_show
  # --------
  # STAGE 1 RULE-OUT REPORT
  get '/projects/:id/genboree_ac/ui/stg1RuleOutRpt', :to => "genboree_ac_ui_stg1_rule_out_report#show", :as => :genboree_ac_ui_stg1_rule_out_report
    # --------
  # STAGE 2 SUMMARY REPORT
  get '/projects/:id/genboree_ac/ui/stg2SummaryRpt', :to => "genboree_ac_ui_stg2_summary_report#show", :as => :genboree_ac_ui_stg2_summary_report
  # --------
  # MISC / SETTINGS / ETC
  post '/genboree_ac/update', :to => "genboree_ac_settings#update", :as => :genboree_ac_settings_update

  # --------
  # PROTO  - temp not for deploy
  get '/projects/:id/genboree_ac/proto/put/grp/:grpName', :to => 'put_proto#putGrp'
  get '/projects/:id/genboree_ac/proto/delete/grp/:grpName', :to => 'delete_proto#deleteGrp'
end
