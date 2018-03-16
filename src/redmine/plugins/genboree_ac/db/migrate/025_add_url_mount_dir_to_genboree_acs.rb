class AddUrlMountDirToGenboreeAcs < ActiveRecord::Migration
  def change
    add_column :genboree_acs, :urlMountDir, :string
  end
end
