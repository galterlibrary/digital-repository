class CollectionStore
  attr_accessor :data

  def initialize
    @data = Hash.new
  end

  def build_collection_store_data
    Collection.find_each do |c|
      @data[c.id] = {
        "id": c.id,
        "title": c.title,
        "parent_ids": c.collection_ids,
        "paths": []
      }
    end
  end

  def build_paths_for_collection_store
    @data.each do |id, collection|
      recursive_collection_path(
        collection,
        [collection_title_id_data(collection)],
        collection
      )
    end
  end

  private
  def recursive_collection_path(collection, path, starting_collection)
    if collection[:parent_ids].empty?
      starting_collection[:paths] << path
    else
      collection[:parent_ids].each do |parent_id|
        if collection_already_in_path?(parent_id, path)
          starting_collection[:paths] << path
          next
        end

        parent_collection = @data[parent_id]

        recursive_collection_path(
          parent_collection,
          [collection_title_id_data(parent_collection)] + path,
          starting_collection
        )
      end
    end
  end

  def collection_already_in_path?(collection_id, path)
    path.map{|p|  p[:id]}.include?(collection_id)
  end

  def collection_title_id_data(collection)
    {"title": collection[:title], "id": collection[:id]}
  end
end
