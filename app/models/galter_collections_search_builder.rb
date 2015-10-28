class GalterCollectionsSearchBuilder < Hydra::Collections::SearchBuilder
  def all_rows(solr_parameters)
    solr_parameters[:rows] = 999999
  end

  def root_collections(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << '-isPartOf_ssim:[* TO *]'
  end
end
