# 827 Series IV Photographs Collection Changes
# Move all records in each Series IV subcollection to Series IV collection,
# and delete each subocllection.

series_iv_collection = Collection.find("x346d4254")
# series_iv_collection = Collection.find("fj236226r") # staging example

series_iv_collection.members.each do |subcollection|
  if subcollection.class == Collection
    subcollection.members.each do |member|
      if member.class == Page
        series_iv_collection.members << member
        member.combined_file = nil
        member.save!
      end
    end
    subcollection.combined_file = nil
    subcollection.save!
  end
end

series_iv_collection.save!
