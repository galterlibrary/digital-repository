# A generic job for sending events about a collections to the followers.
#
# @attr [String] collection_id the id of the file the event is specified for
#
class CollectionEventJob < EventJob
  attr_accessor :collection_id

  def initialize(collection_id, depositor_id)
    super(depositor_id)
    @collection_id = collection_id
  end

  def run
    super

    log_collection_event
  end

  def collection
    @collection ||= Collection.load_instance_from_solr(collection_id)
  end

  # Log the event to the Collections's stream
  def log_collection_event
    collection.log_event(event) unless collection.nil?
  end

  # override to check file permissions before logging to followers
  def log_to_followers
    depositor.followers.select { |user|
      user.can?(:read, collection)
    }.each do |follower|
      follower.log_event(event)
    end
  end

  # log the event to the users profile stream
  def log_user_event
    depositor.log_profile_event(event)
  end

  def link_to_collection(col=nil)
    col ||= collection
    link_to(
      col.title,
      Hydra::Collections::Engine.routes.url_helpers.collection_path(col)
    )
  end
end
