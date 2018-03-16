require 'brl/util/util'

module GenboreeAcHelper
  module PermHelper
    # ----------------------------------------------------------------
    # BEFORE_FILTERS - useful before_filter methods for your controller
    # ----------------------------------------------------------------
    def userPerms()
      @userPerms    = pluginUserPerms(:genboree_ac, @project, @currRmUser)
      @userPermsJS  = pluginUserPerms(:genboree_ac, @project, @currRmUser, :as => :javascript)
    end

    # ----------------------------------------------------------------

    def pluginPerms(plugin=:genboree_ac, opts={ :as => :permObj })
      retVal = []
      # Get all Permission objects for the plugin
      perms = Redmine::AccessControl.permissions.find_all { |perm| perm.project_module == plugin }
      # Get as type wanted
      if(opts[:as] == :symbol)
        retVal = perms.collect() { |perm| perm.name }
      elsif(opts[:as] == :string)
        retVal = perms.collect() { |perm| perm.name.to_s }
      else # as Permission object
        retVal = perms
      end
      return retVal
    end
    
    def pluginUserPerms(plugin, project, user, opts={ :as => :hash})
      retVal = nil
      # Get all permission symbols for the plugin
      perms = pluginPerms(plugin, :as => :symbol)
      # Find if user allowed in project for each permission
      permMap = {}
      perms.each { |perm|
        userAllowed = user.allowed_to?(perm, project)
        permMap[perm] = userAllowed
      }
      # Get as type wanted
      if(opts[:as] == :javascript)
        js = "var pluginUserPerms = {"
        permMap.each_key { |perm|
          js << " #{perm} : #{permMap[perm]},"
        }
        js.chomp!(',')
        js << ' } ;'
        retVal = js
      else # as :hash
        retVal = permMap
      end
      return retVal
    end
  end
end
