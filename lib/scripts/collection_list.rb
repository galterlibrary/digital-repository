def collections_path(collection)
  starting_collection_data = collection_title_id_data(collection)
  if collection.collections.empty?
    collection_paths = [[starting_collection_data]]
  else
    collection_paths = []
  end

  collection.collections.each do |parent_collection|
    recursive_collection_path(
      parent_collection,
      [collection_title_id_data(parent_collection),
       starting_collection_data],
      collection_paths
    )
  end

  collection_paths
end

def recursive_collection_path(collection, path, collection_paths)
  if collection.collections.empty?
    collection_paths << path
  else
    collection.collections.each do |collection|
      recursive_collection_path(
        collection,
        [collection_title_id_data(collection)] + path,
        collection_paths
      )
    end
  end
end

def collection_title_id_data(collection)
  {"title": collection.title, "id": collection.id}
end
