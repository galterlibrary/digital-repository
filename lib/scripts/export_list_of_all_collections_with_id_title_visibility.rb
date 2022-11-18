require 'csv'

def map_visibility(collection_visibility)
   if collection_visibility == "open"
     "Open Access"
   elsif collection_visibility == "restricted"
     "Private"
   elsif collection_visibility == "authenticated"
     "Northwestern University"
   else
     collection_visibility
   end
end

def url(collection_id)
  "https://digitalhub.northwestern.edu/collections/#{collection_id}"
end

headers = ["ID", "Title", "Visibility", "URL"]
CSV.open("digitalhub_collections.csv", "w", write_headers: true, headers: headers) do |csv|
  Collection.all.each do |collection|
    csv << [collection.id, collection.title, map_visibility(collection.visibility), url(collection.id)]
  end
end
