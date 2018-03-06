# A specific job to log collection creation to a user's activity streams
class CollectionCreateEventJob < CollectionEventJob
  def action
    @action ||= "User #{link_to_profile depositor_id} has created a new Collection #{link_to collection.title, Hydra::Collections::Engine.routes.url_helpers.collection_path(collection)}"
  end
end
