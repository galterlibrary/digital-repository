# Add 'Nathan Smith Davis papers' to 'Special Collections'
# then convert to institutional

parent_special_collections = Collection.find("v405s9425")

davis_papers = Collection.find("2c2b4dd2-3cb0-4281-9773-53c18c213e86")

parent_special_collections.members << davis_papers
parent_special_collections.save!

davis_papers.convert_to_institutional(
  "institutional-galter",
  parent_special_collections.id,
  "Galter-Collections-Root-Admin"
)
