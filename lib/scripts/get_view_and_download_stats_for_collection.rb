# script for retreiving all page views and download stats from google analytics
# To execute, from the root of this application run:
# current_sufia/ $ bundle exec rails runner lib/scripts/get_view_and_download_stats_for_collection.rb

require './collection_members_view_and_download_stats'

# NUCATS Grants Repository
nucats_grants_repository_stats = CollectionMembersViewAndDownloadStats.new(
  "f2bf6e1d-0e32-4ce2-a52e-bb0522d5708d"
)
nucats_grants_repository_stats.get_stats_and_add_to_csv(type: "pageviews")
nucats_grants_repository_stats.get_stats_and_add_to_csv(type: "downloads")
