class ChangeSourceUrlInDsOrganisations < ActiveRecord::Migration
  def change
    remove_index :ds_organisations, name: :source_url_index
    change_column :ds_organisations, :source_url, :text
  end
end
