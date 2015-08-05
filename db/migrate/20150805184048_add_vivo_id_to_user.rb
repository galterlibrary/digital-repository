class AddVivoIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :vivo_id, :string
  end
end
