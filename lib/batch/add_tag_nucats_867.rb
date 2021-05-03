require "#{Rails.root}/lib/batch/add_tags_for_collection_members"
# batch updates for https://github.com/galterlibrary/digital-repository/issues/867

nucats_grants_repository_id = "f2bf6e1d-0e32-4ce2-a52e-bb0522d5708d"
nucats_tags = ["NUCATS Grants Repository"]
add_tag_for_collection_members(collection_id: nucats_grants_repository_id, tags: nucats_tags)
