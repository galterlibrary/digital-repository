class UpdateCollectionsIndex < ActiveRecord::Migration
  def change
    Collection.all.each {|col| col.update_index }
  end
end
