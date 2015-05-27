class AddDescriptionToRole < ActiveRecord::Migration
  def change
    add_column :roles, :description, :text
    User.all.each {|u| u.add_to_nuldap_groups }
  end
end
