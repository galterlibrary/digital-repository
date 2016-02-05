module InstitutionalCollectionPermissions
  extend ActiveSupport::Concern

  included do
    include Hydra::PermissionsQuery
    include Blacklight::SearchHelper
  end

  def get_solr_doc(object_id)
    resp = ActiveFedora::SolrService.instance.conn.get(
      'select', params: { q: "id:#{object_id}" })
    if resp['response']['numFound'] == 0
      raise Blacklight::Exceptions::InvalidSolrID.new(
        "Parent collection: #{object_id} was not found")
    end
    resp['response']['docs'].first
  end
  private :get_solr_doc

  def get_all_parents(object_id)
    resp = ActiveFedora::SolrService.instance.conn.get(
      'select', params: { q: "hasCollectionMember_ssim:#{object_id}" })
    return [] if resp['response']['numFound'] == 0
    resp['response']['docs'].map do |doc|
      { id: doc['id'],
        institutional_collection: doc['institutional_collection_bsi'] }
    end
  end
  private :get_solr_doc

  def admin_edit_perms_for(object_id)
    doc = get_permissions_solr_response_for_doc_id(object_id)
    return [] if doc.nil?
    (doc[Ability.edit_group_field] || []).select {|agent_name|
      agent_name.match(/-Admin\z/) }
  end
  private :admin_edit_perms_for

  def is_institutional_collection?(object_id)
    get_solr_doc(object_id)['institutional_collection_bsi']
  end
  private :is_institutional_collection?

  def missing_parent_permissions(parent_id)
    admin_edit_perms_for(parent_id) - admin_edit_perms_for(id)
  end
  private :missing_parent_permissions

  def common_permissions(parent_id)
    to_remove = admin_edit_perms_for(parent_id) & admin_edit_perms_for(id)
    other_parents_permissions = get_all_parents(self.id).inject([]) {|arr,col|
      next arr unless col[:institutional_collection]
      arr + admin_edit_perms_for(col[:id])
    }.flatten.compact
    to_remove - other_parents_permissions
  end
  private :common_permissions

  def add_institutional_admin_permissions(parent_id)
    return unless is_institutional_collection?(parent_id)
    # Using #changed? to detect permission_ids changes doesn't work
    # and Solr index doesn't get updated with new permissions.
    permissions_changed = false
    missing_parent_permissions(parent_id).each do |group_name|
      self.permissions.create(name: group_name, type: 'group', access: 'edit')
      permissions_changed = true
    end
    self.reload.update_index if permissions_changed
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
