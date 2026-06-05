class AddSuperuserToAdminsAndAdminIdToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :superuser, :boolean, default: false, null: false
    add_column :projects, :admin_id, :integer
    add_index :projects, :admin_id
  end
end
