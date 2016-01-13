class AddPlaceToDsOrganisations < ActiveRecord::Migration
  def change
    add_column :ds_organisations, :place, :string
  end
end
