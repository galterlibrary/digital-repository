class AddLdapNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :formal_name, :string
  end
end
