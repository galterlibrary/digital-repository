# A specific job to log collection's member removal to a user's activity streams
class CollectionMemberRemoveEventJob < CollectionEventJob
  def initialize(collection_id, child_id, depositor_id)
    super(collection_id, depositor_id)
    @depositor_id = depositor_id
    @child_id = child_id
  end

  def run
    super

    # Notify followers of the parent collections of the child object
    log_to_all_followers(collection, @child_id, object_removal=true)
  end

  def action
    @action ||= "User #{link_to_profile depositor_id} has removed #{@child_id} from Collection #{link_to_collection}"
  end
end
