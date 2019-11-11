# script for retrieving all page views and download stats from google analytics
# To execute, from the root of this application run:
# current_sufia/ $ bundle exec rails runner lib/scripts/get_view_and_download_stats_for_collection.rb "REPLACE WITH COLLECTION ID"

if ARGV.length != 1
  puts "Need collection ID argument!!"
  exit
end

require "#{Rails.root}/lib/scripts/collection_members_view_and_download_stats"

collection_members_stats = CollectionMembersViewAndDownloadStats.new(
  ARGV[0]
)

collection_members_stats.get_stats_and_add_to_csv(type: "pageviews")
collection_members_stats.get_stats_and_add_to_csv(type: "downloads")
