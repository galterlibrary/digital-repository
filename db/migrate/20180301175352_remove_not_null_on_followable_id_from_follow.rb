class RemoveNotNullOnFollowableIdFromFollow < ActiveRecord::Migration
  def up
    change_column :follows, :followable_id, :integer, null: true
    add_index :follows, [:followable_id, :followable_fedora_id], unique: true
  end

  def down
    change_column :follows, :followable_id, :integer, null: false
    remove_index :follows, [:followable_id, :followable_fedora_id]
  end
end
