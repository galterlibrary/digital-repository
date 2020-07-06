# Batch update subject_geographic for GenericFile and Collection. 
# Need simple solr_query tearm to search index, an array of old_terms to match,
# and new_term to replace or add.

def batch_update_subject_geographic(solr_query:, old_terms: [], new_term:)
  solr_objects = ActiveFedora::SolrService.query("subject_geographic_tesim:\"#{solr_query}\"", { rows: 99999 })

  solr_objects.each do |solr_object|
    # could be either Collection or GenericFile, so we convert the string to
    # class to get the object by id
    object_constant = solr_object['has_model_ssim'].first.constantize
    object = object_constant.find(solr_object['id'])

    object.subject_geographic.each do |geographic|
      if old_terms.map(&:downcase).include?(geographic.downcase)
        # If there are multiple matches, new_term will not be saved twice.
        object.subject_geographic += [new_term]
        object.subject_geographic -= [geographic]
      end
    end

    object.save!
  end
end
