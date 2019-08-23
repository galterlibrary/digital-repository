# https://github.com/galterlibrary/digital-repository/issues/678
# New collections under NUCATS Grants Repository
#   - Federal Non-NIH Awards
#   - U-series
#   - R-Series
#     - move R01, R03, R21 collections here
#   - Grants Resources
#     - Pink Sheets
#     - Biosketches

# NUCATS Grants Repository
parent_nucats_grants = Collection.find("f2bf6e1d-0e32-4ce2-a52e-bb0522d5708d")

# Federal Non-NIH Awards
fed_non_nih = Collection.new(
  title: "Federal Non-NIH Awards",
  tag: ["grant proposals", "research support", "peer-reviewed grants"]
)
fed_non_nih.apply_depositor_metadata(parent_nucats_grants.depositor)
fed_non_nih.save!

parent_nucats_grants.members << fed_non_nih
parent_nucats_grants.save!

fed_non_nih.convert_to_institutional("institutional-nucats-grants-repository", parent_nucats_grants.id)

# U-Series
u_series = Collection.new(
  title: "U-Series",
  tag: ["grant proposals", "research support", "peer-reviewed grants"]
)
u_series.apply_depositor_metadata(parent_nucats_grants.depositor)
u_series.save!

parent_nucats_grants.members << u_series 
parent_nucats_grants.save!

u_series.convert_to_institutional("institutional-nucats-grants-repository", parent_nucats_grants.id)

# R-Series
r_series = Collection.new(
  title: "R-Series",
  tag: ["grant proposals", "research support", "peer-reviewed grants"]
)
r_series.apply_depositor_metadata(parent_nucats_grants.depositor)
r_series.save!

parent_nucats_grants.members << r_series 
parent_nucats_grants.save!

# Add R01, R03, R21 collections
# note: removing these collections from NUCATS Grants Repository collection 
# can be done on the frontend
r01 = Collection.find("6a9690f5-664a-4654-a5ca-c1c1ca99db9b")
r03 = Collection.find("49945521-3b35-4efd-9e77-e909900f1604")
r21 = Collection.find("af85d02b-4b6c-48db-8cac-b82f4075e1f0")
r_series.members << r01
r_series.members << r03
r_series.members << r21
r_series.save!

r_series.convert_to_institutional("institutional-nucats-grants-repository", parent_nucats_grants.id)

# Grants Resources
grants_resources = Collection.find("691ddbbd-785c-4a6a-85d1-7569d8fcbcdb")

# Pink Sheets
pink_sheets = Collection.new(
  title: "Pink Sheets",
  tag: ["grant proposals", "research support", "peer-reviewed grants"]
)
pink_sheets.apply_depositor_metadata(parent_nucats_grants.depositor)
pink_sheets.save!

grants_resources.members << pink_sheets 
grants_resources.save!

pink_sheets.convert_to_institutional("institutional-nucats-grants-repository", parent_nucats_grants.id)

# Biosketches
biosketches = Collection.new(
  title: "Biosketches",
  tag: ["grant proposals", "research support", "peer-reviewed grants"]
)
biosketches.apply_depositor_metadata(parent_nucats_grants.depositor)
biosketches.save!

grants_resources.members << biosketches 
grants_resources.save!

biosketches.convert_to_institutional("institutional-nucats-grants-repository", parent_nucats_grants.id)
