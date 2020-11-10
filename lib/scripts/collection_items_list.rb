require 'csv'

class CollectionItemsList
  attr_accessor :collection, :collection_items_csv_file

  def initialize(collection)
    @collection = Collection.find(collection)
    @collection_items_csv_file = CSV.open(
      File.join(Rails.root, "/lib/scripts/results/#{sanitize_title(@collection.title)}_items_list.csv"),
      "w"
    )
    @collection_items_csv_file << ["Collection Name", "File Name", "File URI"]
  end

  def sanitize_title(collection_title)
    collection_title.gsub(/[^0-9A-Z]/i, '_')
  end

  def get_items_and_add_to_csv(collection: self.collection)
    csv_file = self.collection_items_csv_file

    collection.members.each do |member|
      if member.class == Collection
        self.get_items_and_add_to_csv(collection: member)
        next
      end

      member_uri = "https://digitalhub.northwestern.edu/files/#{member.id}"

      if csv_file.closed?
        csv_file.reopen(csv_file.path, "a")
      end

      csv_file << [collection.title, member.title.first, member_uri]
    end

    csv_file.close
  end
end
