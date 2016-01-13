class AddIndexToDocIdInStaRegisMain < ActiveRecord::Migration
  def change
    add_index :sta_regis_main, :doc_id
  end
end
