class AddReleasedMqConfToGenboreeAcs < ActiveRecord::Migration
  def change
    add_column :genboree_acs, :releasedMqConf, :string, :default => ''
  end
end
