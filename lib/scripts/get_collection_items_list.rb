# script for getting list of all items in a collection
# To execute, from the root of this application run:
# current_sufia/ $ bundle exec rails runner lib/scripts/get_collection_items_list.rb "REPLACE WITH COLLECTION ID"

if ARGV.length != 1
  puts "Need collection ID argument!!"
  exit
end

require "#{Rails.root}/lib/scripts/collection_items_list"

collection_items_list = CollectionItemsList.new(
  ARGV[0]
)

collection_items_list.get_items_and_add_to_csv
