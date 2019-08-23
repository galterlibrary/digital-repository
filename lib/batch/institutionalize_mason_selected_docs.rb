# Create new "Mason Selected Documents", and add to "Michael L. Mason"
# collection, then convert to institutional

parent_mason_collection = Collection.find("b0a1fa15-eb29-416f-b452-e81b39f0f26b")

mason_selected_docs = Collection.new(
  title: 'Mason Selected Documents',
  tag: ["World War II", "12th General Hospital"]
)

mason_selected_docs.apply_depositor_metadata(parent_mason_collection.depositor)
mason_selected_docs.save!

parent_mason_collection.members << mason_selected_docs 
parent_mason_collection.save!

mason_selected_docs.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)

