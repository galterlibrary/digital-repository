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
        "collections": c.collection_ids,
        "paths": []
      }
    end
  end

  def build_paths_for_collection_store
    @data.each do |collection|
      collection_data = collection[1]
      recursive_collection_path(
        collection_data,
        [collection_title_id_data(collection_data)],
        collection_data
      )
    end
  end

  private
  def recursive_collection_path(collection, path, starting_collection)
    if collection[:collections].empty?
      starting_collection[:paths] << path
    else
      collection[:collections].each do |parent_collection|
        parent_collection_data = @data[parent_collection]

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
end
