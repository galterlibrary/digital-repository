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
  private :get_all_parents

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

  def nodes_depositor(object_id)
    get_solr_doc(object_id)['depositor_tesim'].first
  end
  private :nodes_depositor

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

  def convert_to_institutional(depositor_name, parent_id=nil, root_admin=nil)
    unless self.is_a?(Collection)
      adjust_institutional_permissions(parent_id)
      self.save!
      return
    end

    set_root_admin_group(root_admin)
    make_institutional(depositor_name, parent_id)
    self.members.flatten.compact.each do |child|
      child.convert_to_institutional(depositor_name, self.id)
    end
  end

  def normalize_institutional(depositor_name=nil, group_name=nil, parent_id=nil)
    parent_id ||= self.id
    return unless is_institutional_collection?(parent_id)

    adjust_institutional_permissions(parent_id)
    return unless self.is_a?(Collection)

    set_root_admin_group(group_name) if group_name.present?
    normalize_institutional_depositor(depositor_name, parent_id)
    self.save!
    self.members.flatten.compact.each do |child|
      child.normalize_institutional(depositor_name, nil, self.id)
    end
  end

  def is_root_node?
    self.collections.blank?
  end

  def set_root_admin_group(root_admin)
    # Only add group permissions when:
    # - `root_admin' is specified
    # - `root_admin' is not specified and this is a root node
    return if root_admin.blank? && !is_root_node?
    if root_admin.blank?
      root_admin = self.title.strip
                             .slice(0..40)
                             .encode(Encoding::US_ASCII, {
                               :invalid => :replace,
                               :undef => :replace,
                               :replace => '' })
                             .gsub(/\s/, '-') << '-Admin'
    end
    return if self.permissions.map(&:agent_name).include?(root_admin)
    self.permissions.create(name: root_admin, type: 'group', access: 'edit')
  end
  private :set_root_admin_group

  def adjust_institutional_permissions(parent_id)
    return if parent_id.blank? || parent_id == self.id
    missing_parent_permissions(parent_id).each do |group_name|
      self.permissions.create(name: group_name, type: 'group', access: 'edit')
    end
  end
  private :adjust_institutional_permissions

  def find_depositor_name(depositor_name, parent_id)
    depositor_name.strip!
    unless depositor_name.to_s =~ /^institutional-/
      raise "Depositor #{depositor_name} has to start with `institutional-'"
    end

    if parent_id.blank? || is_root_node?
      return depositor_name if depositor_name =~ /-root$/
      depositor_name << '-root'
    else
      depositor_name.gsub(/-root/, '')
    end
  end
  private :find_depositor_name

  def normalize_institutional_depositor(depositor_name, parent_id)
    return unless self.institutional_collection
    return if depositor_name.blank? && parent_id.blank?

    if parent_id.present? && depositor_name.blank?
      depositor_name = nodes_depositor(parent_id)
    end
    set_institutional_depositor(depositor_name, parent_id)
  end

  def set_institutional_depositor(depositor_name, parent_id)
    depositor_name = find_depositor_name(depositor_name, parent_id)
    unless depositor_user = User.find_by(username: depositor_name)
      depositor_user = User.create!(username: depositor_name,
                                    email: "#{depositor_name}@northwestern.edu")
    end
    return if self.depositor == depositor_user.username
    self.apply_depositor_metadata(depositor_user.username)
  end
  private :set_institutional_depositor

  def make_institutional(depositor_name, parent_id)
    adjust_institutional_permissions(parent_id)
    set_institutional_depositor(depositor_name, parent_id)
    self.institutional_collection = true
    self.save!
  end
  private :make_institutional
end
