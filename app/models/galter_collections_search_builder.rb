class GalterCollectionsSearchBuilder < Hydra::Collections::SearchBuilder
  def all_rows(solr_parameters)
    solr_parameters[:rows] = 999999
  end
end
