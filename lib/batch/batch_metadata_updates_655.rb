# Transfer metadata values from Original Publisher to Digital Publisher field

# below is too slow, overloads the memory
#items_needing_transfer = GenericFile.all.reject { |gf| 
#                           gf.original_publisher == []
#                         }

solr_items_w_original_publisher_value = ActiveFedora::SolrService.query(
                                     'original_publisher_tesim:*', 
                                     { rows: 99999 }
                                   )

solr_items_w_original_publisher_value.each do |solr_item|
  # could be either Collection or GenericFile, so we convert the string to
  # class to get the object by id
  constant_item = solr_item['has_model_ssim'].first.constantize
  item = constant_item.find(solr_item['id'])

  item.original_publisher.each do |op|
    if !item.publisher.include?(op)
      item.publisher += [op]
    end
  end

  item.original_publisher = []
  item.save!
end
