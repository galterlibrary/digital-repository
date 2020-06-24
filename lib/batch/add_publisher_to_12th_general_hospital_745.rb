require "#{Rails.root}/lib/batch/add_publisher_for_collection_members"
# batch updates for https://github.com/galterlibrary/digital-repository/issues/745

twelfth_general_hospital_id = "07b25bee-4a47-466a-b9b8-70d7a392fab0"
add_publisher_for_collection_members(collection_id: twelfth_general_hospital_id)
