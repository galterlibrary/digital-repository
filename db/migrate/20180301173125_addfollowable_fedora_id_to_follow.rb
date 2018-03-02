class AddfollowableFedoraIdToFollow < ActiveRecord::Migration
  def change
    add_column :follows, :followable_fedora_id, :string
  end
end
