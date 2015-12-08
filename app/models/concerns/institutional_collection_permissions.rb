module InstitutionalCollectionPermissions
  extend ActiveSupport::Concern

  included do
    include Hydra::PermissionsQuery
    include Blacklight::SearchHelper
  end

  def admin_edit_perms_for(object_id)
    doc = get_permissions_solr_response_for_doc_id(object_id)
    return [] if doc.nil?
    (doc[Ability.edit_group_field] || []).select {|agent_name|
      agent_name.match(/-Admin\z/) }
  end
  private :admin_edit_perms_for

  def is_institutional_collection?(parent_id)
    resp = ActiveFedora::SolrService.instance.conn.get(
      'select', params: { q: "id:#{parent_id}" })
    if resp['response']['numFound'] == 0
      raise Blacklight::Exceptions::InvalidSolrID.new(
        "Parent collection: #{parent_id} was not found")
    end
    resp['response']['docs'].first['institutional_collection_bsi']
  end
  private :is_institutional_collection?

  def missing_parent_permissions(parent_id)
    admin_edit_perms_for(parent_id) - admin_edit_perms_for(id)
  end
  private :missing_parent_permissions

  def common_permissions(parent_id)
    admin_edit_perms_for(parent_id) & admin_edit_perms_for(id)
  end
  private :common_permissions

  def add_institutional_admin_permissions(parent_id)
    return unless is_institutional_collection?(parent_id)
    # Using #changed? to detect permission_ids changes doesn't work
    # and Solr index doesn't get updated with new permissions.
    permissions_changed = false
    missing_parent_permissions(parent_id).each do |group_name|
      permissions_changed = true
      self.permissions.create(name: group_name, type: 'group', access: 'edit')
    end
    self.update_index if permissions_changed
  end

  def remove_institutional_admin_permissions(parent_id)
    return unless is_institutional_collection?(parent_id)
    # Using #changed? to detect permission_ids changes doesn't work
    # and Solr index doesn't get updated with new permissions.
    permissions_changed = false
    if to_remove = common_permissions(parent_id)
      permissions_changed = true
      self.permissions.each do |perm|
        perm.destroy if to_remove.include?(perm.agent_name)
      end
    end
    self.reload.update_index if permissions_changed
  end
end
