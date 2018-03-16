class AddIsAcReleaseTrackToGenboreeAcs < ActiveRecord::Migration
  def change
    add_column :genboree_acs, :isAcReleaseTrack, :boolean, :default => 0
  end
end

