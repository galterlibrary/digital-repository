# Institutionalize the following collections into Mason and Connor 
# sub-collections

# Mason sub-collections
# - Mason Reports
# - Mason Publications
# - Mason Procedures
# - Mason Ephemera
# - Mason Postcards
# - Mason WWI

parent_mason_collection = Collection.find("b0a1fa15-eb29-416f-b452-e81b39f0f26b")

mason_reports_collection = Collection.find("1a3c738a-ba69-4275-98b0-fc77939d5b93")
mason_publications_collection = Collection.find("129331fe-295c-422b-908c-822700382bac")
mason_procedures_collection = Collection.find("bc454378-fa71-40a4-b7dc-d671bdb9a2f2")
mason_ephemera_collection = Collection.find("1e364bb6-9536-4680-abd8-c784e5e964d0")
mason_postcards_collection = Collection.find("1e364bb6-9536-4680-abd8-c784e5e964d0")
mason_wwi_collection = Collection.find("57b30ff8-9d78-49c8-9f62-0139fe22845d")
mason_AinelTurck_architectural_plans_collection = Collection.find("bda03672-47c5-4b11-ad26-343eca1e9ce2")

parent_mason_collection.members << mason_reports_collection
parent_mason_collection.members << mason_publications_collection
parent_mason_collection.members << mason_procedures_collection
parent_mason_collection.members << mason_ephemera_collection
parent_mason_collection.members << mason_postcards_collection
parent_mason_collection.members << mason_wwi_collection
parent_mason_collection.members << mason_AinelTurck_architectural_plans_collection 
parent_mason_collection.save!

mason_reports_collection.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
mason_publications_collection.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
mason_procedures_collection.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
mason_ephemera_collection.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
mason_postcards_collection.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
mason_wwi_collection.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
mason_AinelTurck_architectural_plans_collection.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)

# Conner sub-collections
# - Conner Medical Officer Bios
# - Conner Ephemera
# - Conner Selected Documents
# - Conner Photographs
# - Conner Insignia

parent_conner_collection = Collection.find("a97853c7-82d3-408c-95d8-c72a04acb41f")

conner_medical_officer_bios = Collection.find("aed04ba0-5b58-4a10-94de-cc062d44bcfc")
conner_ephemera = Collection.find("b37f04ab-f9d6-4e97-a896-6e63d0586c9b")
conner_selected_documents = Collection.find("898c31c9-b407-46e9-b923-7bd7f7fdae42")
conner_photographs = Collection.find("102d9812-55fa-4aeb-b910-04e534f7a7ef")
conner_insignia = Collection.find("7b81356b-6eaa-4570-bd18-355714700aed")

parent_conner_collection.members << conner_medical_officer_bios
parent_conner_collection.members << conner_ephemera
parent_conner_collection.members << conner_selected_documents
parent_conner_collection.members << conner_photographs
parent_conner_collection.members << conner_insignia
parent_conner_collection.save!

conner_medical_officer_bios.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
conner_ephemera.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
conner_selected_documents.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
conner_photographs.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)
conner_insignia.convert_to_institutional(
  "institutional-galter",
  parent_mason_collection.id,
  "Galter-Collections-Root-Admin"
)

