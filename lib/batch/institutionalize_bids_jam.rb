# Institutionalize "Feinberg Biomedical Data Science Day 2106" under 
# "Biomedical Data Science Day"
# Create new "Chicago Biomedical Informatic and Data Science Jam" collection, 
# add member collection "Chicago Biomedical Informatics and Data Science Jam 2016"
# and institutionalize under "Center for Data Science and Informatics"
# https://github.com/galterlibrary/digital-repository/issues/706

biomedical_data_science_day = Collection.find("ab570598-e497-4c81-9351-1aa316252682")
data_science_day_2016 = Collection.find("fbbf335e-4c4a-4f84-8220-631a8014b3fd")

biomedical_data_science_day.members << data_science_day_2016
biomedical_data_science_day.save! 
data_science_day_2016.convert_to_institutional(
  "institutional-center-for-data-science-and-informatics-root",
  biomedical_data_science_day.id
)

chicago_BIDS_jam = Collection.new(
  title: "Chicago Biomedical Informatics and Data Science Jam",
  tag: ["data science", "informatics", "NUCATS", "CDSI"],
  description: "Biomedical and Health Informatics and Data Science (BIDS) "\
               "faculty and students at Northwestern University, University of "\
               "Illinois-Chicago and University of Chicago are invited to "\
               "learn about research and collaboration opportunities across "\
               "Chicago. The event is also a chance for new students to meet "\
               "current students and learn about their research projects."
)

chicago_BIDS_jam.apply_depositor_metadata(
  'institutional-center-for-data-science-and-informatics-system'
)

chicago_BIDS_Jam_2016 = Collection.find("a58d0b93-df89-4f10-9064-fa4e99b79bb1")
chicago_BIDS_jam.members << chicago_BIDS_Jam_2016
chicago_BIDS_jam.save!
chicago_BIDS_jam.reload.convert_to_institutional(
  # the username to be applied
  'institutional-center-for-data-science-and-informatics',
  # Center for Data Science and Informatics
  '2828d181-5de7-4567-ba8d-d6bdb72b625f'
)
