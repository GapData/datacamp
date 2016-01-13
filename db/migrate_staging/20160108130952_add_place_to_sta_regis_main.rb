class AddPlaceToStaRegisMain < ActiveRecord::Migration
  def change
    add_column :sta_regis_main, :place, :string
  end
end
