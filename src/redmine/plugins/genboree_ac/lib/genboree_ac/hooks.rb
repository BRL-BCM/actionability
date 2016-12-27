#!/usr/bin/env ruby


module GenboreeAcSettingsHook
  class Hooks < Redmine::Hook::ViewListener
    def helper_projects_settings_tabs(context = {})
      context[:tabs].push({ :name    => 'genboreeAc',
                          :action  => :genboreeac_settings,
                          :partial => 'projects/settings/genboree_ac_settings',
                          :label   => :gbac_label_project_settings_tab })
    end
  end
end
