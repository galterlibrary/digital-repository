# https://github.com/galterlibrary/digital-repository/issues/690
# Add 'F Series' to 'NUCATS Grants Repository'
# then institutionalize

# NUCATS Grants Repository
parent_nucats_grants_repository = Collection.find("f2bf6e1d-0e32-4ce2-a52e-bb0522d5708d")

f_series = Collection.find("1b2b7d0f-d7f3-41a4-a2a4-8435d719ecec")
parent_nucats_grants_repository.members << f_series
parent_nucats_grants_repository.save!
f_series.convert_to_institutional("institutional-nucats-grants-repository", parent_nucats_grants_repository.id)
