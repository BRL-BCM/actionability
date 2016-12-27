class CreateGenboreeAcs < ActiveRecord::Migration
  def change
    create_table :genboree_acs do |t|
      t.integer :project_id
      t.string :gbHost
      t.string :gbGroup
      t.string :gbKb
      t.string :appLabel
      t.boolean :useRedmineLayout,         :default => 1
      t.string :headerIncludeFileLoc
      t.string :footerIncludeFileLoc
      t.string :actionabilityColl,         :default => 'Actionability Curation'
      t.string :referencesColl,            :default => 'Actionability References'
      t.string :genesColl
    end
  end
end
