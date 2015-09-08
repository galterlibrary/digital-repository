class UserRoles < ActiveRecord::Migration
  def up
    drop_table :user_roles
    drop_table :roles

    create_table :roles do |t|
      t.string :name
    end
    create_table :roles_users, :id => false do |t|
      t.references :role
      t.references :user
    end
    add_index :roles_users, [:role_id, :user_id]
    add_index :roles_users, [:user_id, :role_id]

    Role.create(name: 'admin')
    User.find_by(username: 'phb010').try(:add_role, 'admin')
    User.find_by(username: 'viq454').try(:add_role, 'admin')
  end

  def down
    drop_table :roles_users
    drop_table :roles
  end
end
