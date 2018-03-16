class AddRequireHttpsForApiToGenboreeAcs < ActiveRecord::Migration
  def change
    add_column :genboree_acs, :requireHttpsForApi, :boolean, :default => 0
  end
end
