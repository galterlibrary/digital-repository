def collections_path(collection)
  if collection.collections.empty?
    collection_paths = [[{"title": collection.title, "id": collection.id}]]
  else
    collection_paths = []
  end

  collection.collections.each do |parent_collection|
    recursive_collection_path(
      parent_collection,
      [{"title": parent_collection.title, "id": parent_collection.id},
       {"title": collection.title, "id": collection.id}],
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
        [{"title": collection.title, "id": collection.id}] + path,
        collection_paths
      )
    end
  end
end
