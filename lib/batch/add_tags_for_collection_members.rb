# adds a new tag(s) to all the items in a collection
# Requires a collection_id and array of new tags

def add_tag_for_collection_members(collection_id:, tags:)
  collection = Collection.find(collection_id)

  puts "Checking #{collection.members.count} items in #{collection.title}"
  collection.members.each do |member|
    if member.class == Collection
      add_tag_for_collection_members(collection_id: member.id, tags: tags)
    else
      member.tag += tags
      member.save!
    end
  end
end
