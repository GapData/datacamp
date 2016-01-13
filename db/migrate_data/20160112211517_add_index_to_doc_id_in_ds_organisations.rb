class AddIndexToDocIdInDsOrganisations < ActiveRecord::Migration
  def change
    add_index :ds_organisations, :doc_id
  end
end
