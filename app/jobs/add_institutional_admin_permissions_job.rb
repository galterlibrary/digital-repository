class AddInstitutionalAdminPermissionsJob < ActiveFedoraIdBasedJob
  def queue_name
    :institutional_collections_add_permissions
  end

  attr_accessor :col_id

  def initialize(id, col_id)
    self.id = id
    self.col_id = col_id
  end

  def run
    return unless object.present? && col_id.present?
    object.add_institutional_admin_permissions(col_id)
  end
end
