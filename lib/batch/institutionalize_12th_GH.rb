# Add 'T Series' and 'Grants Resorces' to 'NUCATS Grants Repository'
# then convert to institutional

parent_ghsl_collection = Collection.find("fj2362114")

general_hospital_collection = Collection.find("07b25bee-4a47-466a-b9b8-70d7a392fab0")
parent_ghsl_collection.members << general_hospital_collection 
parent_ghsl_collection.save!
general_hospital_collection.convert_to_institutional("institutional-galter", parent_ghsl_collection.id)
