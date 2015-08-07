class RemoveComments < ActiveRecord::Migration
  def change
    drop_table :comments
    drop_table :comment_ratings
    drop_table :comment_reports
  end
end
