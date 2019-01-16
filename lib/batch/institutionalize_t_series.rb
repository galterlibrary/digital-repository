# Add 'T Series' and 'Grants Resorces' to 'NUCATS Grants Repository'
# then convert to institutional

parent_nucats_grants_repository = Collection.find("f2bf6e1d-0e32-4ce2-a52e-bb0522d5708d")

t_series = Collection.find("22e29a25-6e89-4322-b772-15442ca5b713")
parent_nucats_grants_repository.members << t_series
parent_nucats_grants_repository.save!
t_series.convert_to_institutional("institutional-nucats-grants-repository", parent_nucats_grants_repository.id)

grants_resources = Collection.find("691ddbbd-785c-4a6a-85d1-7569d8fcbcdb")
parent_nucats_grants_repository.members << grants_resources 
parent_nucats_grants_repository.save!
grants_resources.convert_to_institutional("institutional-nucats-grants-repository", parent_nucats_grants_repository.id)
