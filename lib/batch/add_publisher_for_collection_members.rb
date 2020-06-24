# updates all the items in a collection with no publisher value.
# Requires a collection_id

def add_publisher_for_collection_members(collection_id:)
  collection = Collection.find(collection_id)

  puts "Checking #{collection.members.count} items in #{collection.title} for empty publisher"
  collection.members.each do |member|
    if member.class == Collection
      add_publisher_for_collection_members(collection_id: member.id)
    end

    member.update(publisher: ["DigitalHub. Galter Health Sciences Library & Learning Center"]) if member.publisher.blank?
  end
end
