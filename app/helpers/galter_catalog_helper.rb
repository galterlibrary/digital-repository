module GalterCatalogHelper
  def hydra_object_path(work)
    path = (work.hydra_model == 'Collection') ? '/collections/' : '/files/'
    path + work.id
  end
end
