class AddTemplateSetsCollToGenboreeAcs < ActiveRecord::Migration
  def change
    add_column :genboree_acs, :templateSetsColl, :string
  end
end
