class CreateRole < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :role
      t.text :description
    end

    create_table :user_roles do |t|
      t.belongs_to :user
      t.belongs_to :role
    end
    add_index :user_roles, :role_id
    add_index :user_roles, :user_id

  end
end
