class ChangeSourceUrlInStaRegisMain < ActiveRecord::Migration
  def change
    change_column :sta_regis_main, :source_url, :text
  end
end
