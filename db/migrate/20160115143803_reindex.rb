class Reindex < ActiveRecord::Migration
  def change
    ActiveFedora::Base.reindex_everything
  end
end
