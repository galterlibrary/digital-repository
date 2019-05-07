# batch updates for https://github.com/galterlibrary/digital-repository/issues/634

# Updates number 1:
# - All items with "Pediatric Neurology Briefs Publishers" in the Original 
#   Publisher field --> Add additional field to Digital Publisher with "Pediatric 
#   Neurology Briefs Publishers" and delete from Original Publisher

pnb_publishers = "Pediatric Neurology Briefs Publishers"
items_needing_original_publisher_updates = GenericFile.where("original_publisher" => pnb_publishers) + 
                                           Collection.where("original_publisher" => pnb_publishers)

items_needing_original_publisher_updates.each do |item|
  item.publisher += [pnb_publishers]
  item.original_publisher -= [pnb_publishers]
  item.save!
end


# Updates number 2:
# - All items in Science in Society Collection - delete "Science in Society" 
#   from Original Publisher 

sis_publisher = "Science in Society"

def update_sis_original_publisher(id)
  collection = Collection.find(id)

  collection.members.each do |member|
    if member.class == Collection 
      update_sis_original_publisher(member.id)
    else
      member.original_publisher -= [sis_publisher]
      member.save!
    end
  end

  collection.original_publisher -= [sis_publisher]
  collection.save!
end

sis_collection = "93c81706-47f8-49a1-88a2-3acbc971f4ed"
update_sis_original_publisher(sis_collection)


# Updates number 3:
# - All DigitalHub items - delete "Chicago, Illinois, United States" 
#   and delete "Chicago, IL, USA" from Location

chicago_locations = ["Chicago, Illinois, United States", "Chicago, IL, USA"]
items_needing_based_near_updates = GenericFile.where("based_near" => chicago_locations) +
                                   Collection.where("based_near" => chicago_locations)

items_needing_based_near_updates.each do |item| 
  item.based_near -= chicago_locations
  item.save!
end


# Updates number 4:
# - All DigitalHub items with Digital Publisher value 
#   "Galter Health Sciences Library, Feinberg School of Medicine, 
#   Northwestern University" --> change to "Galter Health Sciences Library"

ghsl_fsm_nu_publisher = ["Galter Health Sciences Library, Feinberg School of Medicine, Northwestern University"]
items_needing_publisher_updates = GenericFile.where("publisher" => ghsl_fsm_nu_publisher) + 
                                  Collection.where("publisher" => ghsl_fsm_nu_publisher)

items_needing_publisher_updates.each do |item|
  item.publisher -= ghsl_fsm_nu_publisher
  item.save!
end
