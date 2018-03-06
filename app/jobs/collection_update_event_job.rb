# A specific job to log collection creation to a user's activity streams
class CollectionUpdateEventJob < CollectionEventJob
  def action
    @action ||= "User #{link_to_profile depositor_id} has updated Collection #{link_to_collection}"
  end
end
