# A specific job to log collection update event to a user's activity streams
class CollectionUpdateEventJob < CollectionEventJob
  def run
    super

    # Notify followers of the parent collections of the child object
    log_to_all_followers(collection, collection)
  end

  def action
    @action ||= "User #{link_to_profile depositor_id} has updated Collection #{link_to_collection}"
  end
end
