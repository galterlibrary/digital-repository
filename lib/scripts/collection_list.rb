def build_collection_store_data
  Collection.find_each do |c|
    @collection_store[c.id] = {
      "id": c.id,
      "title": c.title,
      "collections": c.collection_ids,
      "path": []
    }
  end
end

def build_path_for_collection_store
  @collection_store.each do |collection|
    collection_data = collection[1]
    recursive_collection_path(
      collection_data,
      [collection_title_id_data(collection_data)],
      collection_data
    )
  end
end

def recursive_collection_path(collection, path, starting_collection)
  if collection[:collections].empty?
    starting_collection[:path] << path
  else
    collection[:collections].each do |parent_collection|
      parent_collection_data = @collection_store[parent_collection]

      recursive_collection_path(
        parent_collection_data,
        [collection_title_id_data(parent_collection_data)] + path,
        starting_collection
      )
    end
  end
end

def collection_title_id_data(collection)
  {"title": collection[:title], "id": collection[:id]}
end
