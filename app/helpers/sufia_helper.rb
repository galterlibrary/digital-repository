module SufiaHelper
  include ::BlacklightHelper
  include Sufia::BlacklightOverride
  include Sufia::SufiaHelperBehavior

  def user_groups
    current_user.roles.map {|o| [(o.description or o.name), o.name] }
  end

  def render_collection_visibility(document)
    if can?(:edit, document)
      render_visibility_collection_link(document)
    else
      render_visibility_label(document)
    end
  end

  def render_visibility_collection_link(document)
    link_to(
      render_visibility_label(document),
      collections.edit_collection_path(document, { anchor: 'permissions_display' }),
      id: 'permission_'+document.id, class: 'visibility-link'
    )
  end

  def select_viewable_details(terms)
    return terms if can?(:view, :all_details)
    terms.select {|k, v| [:mime_type, :file_size].include?(k) }
  end
end
