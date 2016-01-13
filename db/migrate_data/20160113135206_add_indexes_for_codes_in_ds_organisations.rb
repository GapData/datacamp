class AddIndexesForCodesInDsOrganisations < ActiveRecord::Migration
  def change
    add_index :ds_organisations, :legal_form_code
    add_index :ds_organisations, :activity1_code
    add_index :ds_organisations, :activity2_code
    add_index :ds_organisations, :account_sector
    add_index :ds_organisations, :ownership
    add_index :ds_organisations, :size
  end
end
