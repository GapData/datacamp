class DropWatchers < ActiveRecord::Migration
  def up
    drop_table :watchers
  end

  def down
    create_table :watchers do |t|
      t.string   :email
      t.string   :organization
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
