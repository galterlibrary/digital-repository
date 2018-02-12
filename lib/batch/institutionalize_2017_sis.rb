# Changes the depositor of 2017 Scientific Images Contest Winners 
# to "Institutional-Sis".

sis_2017 = Collection.find("e476cb5c-4200-421a-b8d3-a5262fee3643")
parent_sis = Collection.find("93c81706-47f8-49a1-88a2-3acbc971f4ed")

sis_2017.convert_to_institutional("institutional-sis", parent_sis.id)
