require 'csv'

class CollectionsTagsAndMeshList
  attr_accessor :csv_file

  def initialize
    @csv_file = File.new("#{Rails.root}/lib/scripts/results/collections_tags_and_mesh_list.csv", "w+")
  end

  def populate_collections_tags_and_mesh_info
    CSV.open(self.csv_file.path, "w") do |csv|
      # add headers
      csv << ['Title', 'Link', 'Tags', 'MeSH']

      select_all_collections.each do |collection|
        # remove last "_" part of string
        collection_data = collection.each.map {|k, v| [k.gsub(/_[a-z]+\z/, ''), v] }.to_h
        collection_url = "https://digitalhub.northwestern.edu/collections/#{collection_data['id']}"

        csv << [clean_up_data(collection_data["title"]),
                collection_url,
                clean_up_data(collection_data["tag"]),
                clean_up_data(collection_data["mesh"])]
      end
    end # end block, CSV closes
  end

  private
  def select_all_collections
    # Collection is a fedora object, so using ActiveFedora to get all
    # Collections is slow, and takes up too much memory. Querying solr is much
    # faster, takes up less memory, and still includes the info we want.
    ActiveFedora::SolrService.query('has_model_ssim:Collection', { rows: 99999 } )
  end

  def clean_up_data(value)
    (value.is_a?(Array) ? value.reject(&:blank?).compact.join(" ; ") : value).to_s
  end
end
