class AddReleaseKbBaseUrlToGenboreeAcs < ActiveRecord::Migration
  def change
    add_column :genboree_acs, :releaseKbBaseUrl, :string
  end
end
