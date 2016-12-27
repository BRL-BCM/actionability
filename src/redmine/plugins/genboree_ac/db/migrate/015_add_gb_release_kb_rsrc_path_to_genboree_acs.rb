class AddGbReleaseKbRsrcPathToGenboreeAcs < ActiveRecord::Migration
  def change
    add_column :genboree_acs, :gbReleaseKbRsrcPath, :string
  end
end
