require "#{Rails.root}/lib/scripts/collections_tags_and_mesh"

namespace :collections_tags_and_mesh_list do
  desc "Get list of collections with their tags and mesh in csv"
  task export_collections_tags_and_mesh_list: :environment do
    @collections_tags_and_mesh_list = CollectionsTagsAndMeshList.new

    @collections_tags_and_mesh_list.populate_collections_tags_and_mesh_info

    puts "Export complete, check 'lib/scripts/results/' for csv file"
  end
end
