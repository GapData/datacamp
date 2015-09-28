class ChangeOldDocumentUrlInProcurements < ActiveRecord::Migration
  def up
    update "UPDATE `ds_procurements` SET source_url = REPLACE(source_url, 'http://www.', 'http://www2.')" if ActiveRecord::Base.connection.table_exists? 'ds_procurements'
    update "UPDATE `ds_procurement_v2_notices` SET document_url = REPLACE(document_url, 'http://www.', 'http://www2.') "  if ActiveRecord::Base.connection.table_exists? 'ds_procurement_v2_notices'
    update "UPDATE `ds_procurement_v2_performances` SET document_url = REPLACE(document_url, 'http://www.', 'http://www2.') "  if ActiveRecord::Base.connection.table_exists? 'ds_procurement_v2_performances'
  end

  def down
  end
end
