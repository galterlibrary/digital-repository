# batch updates for https://github.com/galterlibrary/digital-repository/issues/654

def add_digitalhub_to_non_private_empty_publisher_record 
  empty_publisher_items = GenericFile.where(publisher: [])+ 
                          Collection.where(publisher: [])
  puts "updating #{empty_publisher_items.count} records with empty publisher"
  empty_publisher_items.each do |item|
    if item.visibility != "restricted"
      item.publisher += ["DigitalHub. Galter Health Sciences Library & Learning Center"]
      item.save!
    end
  end 
end

def add_digitalhub_to_publisher(publisher)
  solr_items = ActiveFedora::SolrService.query(
    # _sim returns an exact match
    "publisher_sim:\"#{publisher}\"",
    { rows: 99999 }
  )
  puts "updating ALL(#{solr_items.count}) records with publisher #{publisher}"
  solr_items.each do |solr_item|
    constant_item = solr_item['has_model_ssim'].first.constantize
    item = constant_item.find(solr_item['id'])

    # convert to array for easier manipulation
    publisher_array = item.publisher.to_a
    publisher_array.map! { |pub|
      if pub == publisher
        "DigitalHub. #{pub}"
      else
        pub
      end
    }
    item.publisher = publisher_array
    item.save!
  end
end

# Update Publisher field
# - If field is empty && record is NOT private, 
#   add "DigitalHub. Galter Health Sciences Library & Learning Center"
add_digitalhub_to_non_private_empty_publisher_record 

# Update Publisher field (including private records)
# - If field equals "Galter Health Sciences Library & Learning Center", 
#   update to => "DigitalHub. Galter Health Sciences Library & Learning Center"
add_digitalhub_to_publisher("Galter Health Sciences Library & Learning Center")

# Update Publisher field (including private records)
# - If field equals "Galter Health Sciences Library", 
#   update to => "DigitalHub. Galter Health Sciences Library"
add_digitalhub_to_publisher("Galter Health Sciences Library")
