# Fix page_count for records from provided csv list.
# From the root of project, run:
#   `bundle exec rails r lib/scripts/1166_fix_page_count.rb`

require 'csv'

data = CSV.read('./filepaths_of_records_w_invalid_page_count.csv', headers: true)

updated = 0
data.each do |row|
  begin
    generic_file = GenericFile.find(row["dh_id"])
  rescue ActiveFedora::ObjectNotFoundError
    puts "Could not find record for #{row["dh_id"]}"
    next
  end

  begin
    generic_file.page_count = [`pdfinfo #{row["filepath"]} | grep "Pages" | cut -d":" -f 2 | sed 's/ //g'`]
  rescue
    puts "Could not update page_count for #{generic_file.id}"
    next
  end

  updated += 1
  generic_file.save!
end

puts "Updated page_count for #{updated} records"
