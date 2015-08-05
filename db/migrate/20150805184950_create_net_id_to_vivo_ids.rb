class CreateNetIdToVivoIds < ActiveRecord::Migration
  def change
    create_table :net_id_to_vivo_ids do |t|
      t.string :netid, index: true
      t.string :vivoid
      t.string :full_name
      t.timestamps
    end

    CSV.foreach("#{Rails.root}/db/csv/netidsparqlquery.csv",
                headers: true) do |row|
      NetIdToVivoId.create!(netid: row['netid'],
                            full_name: row['name'],
                            vivoid: row['faculty_member'])
    end
  end
end
