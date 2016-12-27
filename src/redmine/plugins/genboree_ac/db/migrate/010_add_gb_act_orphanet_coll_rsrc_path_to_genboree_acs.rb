class AddGbActOrphanetCollRsrcPathToGenboreeAcs < ActiveRecord::Migration
  def change
    add_column :genboree_acs, :gbActOrphanetCollRsrcPath, :string
  end
end
