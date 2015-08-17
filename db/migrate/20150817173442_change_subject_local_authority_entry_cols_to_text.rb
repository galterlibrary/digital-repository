class ChangeSubjectLocalAuthorityEntryColsToText < ActiveRecord::Migration
  def change
    change_column :subject_local_authority_entries, :label, :text
    change_column :subject_local_authority_entries, :url, :text
  end
end
