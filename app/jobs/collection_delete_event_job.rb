# A specific job to log collection creation to a user's activity streams
class CollectionDeleteEventJob < EventJob
  def initialize(deleted_file_id, depositor_id)
    super(depositor_id)
    @deleted_file_id = deleted_file_id
  end

  def action
    @action ||= "User #{link_to_profile depositor_id} has deleted Collection #{@deleted_file_id}"
  end

  def log_user_event
    depositor.log_profile_event(event)
  end
end
