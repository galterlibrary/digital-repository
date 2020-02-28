# Add Ashley Knudson's "Finding Your Way..." to ccb638 user's "2019-2020"
# collection. Add "2019-2020" collection to "Biostatistics Collaboration Center
# Lecture Series"

knudsons_finding_your_way = GenericFile.find("162523bb-47e9-4734-9d75-f9cd59661a58")

ccb638_2019_2020_collection = Collection.find("a86e1412-d72c-4cae-b8ca-16fd834cb128")

ccb638_2019_2020_collection.members << knudsons_finding_your_way 
ccb638_2019_2020_collection.save!

parent_bcc_lecture_series = Collection.find("2cc92425-b656-47ea-a3b4-825405ee6088")
parent_bcc_lecture_series.members << ccb638_2019_2020_collection
parent_bcc_lecture_series.save!
ccb638_2019_2020_collection.convert_to_institutional("institutional-bcc-root", parent_bcc_lecture_series.id)
