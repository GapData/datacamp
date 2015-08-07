class RemoveCommentsFromAbilities < ActiveRecord::Migration
  def up
    AccessRight.where(category: 'comments').each do |access_right|
      ActiveRecord::Base.connection.delete("DELETE FROM access_role_rights where access_right_id = #{access_right.id}")
      ActiveRecord::Base.connection.delete("DELETE FROM user_access_rights where access_right_id = #{access_right.id}")

      access_right.destroy
    end
  end

  def down
    AccessRight.find_or_create_by_category_and_identifier('comments', 'moderate_comments')
    AccessRight.find_or_create_by_category_and_identifier('comments', 'delete_comments')
  end
end
