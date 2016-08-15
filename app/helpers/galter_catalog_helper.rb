module GalterCatalogHelper
  def hydra_object_path(work)
    path = (work.hydra_model == 'Collection') ? '/collections/' : '/files/'
    path + work.id
  end

  def render_catalog_visibility_link(document)
    return if cannot?(:edit, :anything)
    perm_edit_path = sufia.edit_generic_file_path(
      document, anchor: "permissions_display")
    if document.hydra_model == 'Collection'
      perm_edit_path = collections.edit_collection_path(
        document, anchor: "permissions_display")
    end

    link_to(
      render_visibility_label(document),
      perm_edit_path,
      id: "permission_" + document.id,
      class: "visibility-link"
    )
  end
end
