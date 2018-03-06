# A specific job to log collection creation to a user's activity streams
class CollectionUploadEventJob < CollectionEventJob
  def initialize(collection_id, child_id, depositor_id)
    super(collection_id, depositor_id)
    @child_object = ActiveFedora::Base.find(child_id)
  end

  def action
    @action ||= "User #{link_to_profile depositor_id} has added #{link_to_child} to Collection #{link_to_collection}"
  end

  def link_to_child
    if @child_object.is_a?(Collection)
      link_to_collection(@child_object)
    elsif @child_object.is_a?(GenericFile)
      link_to(
        @child_object.title.first,
        Sufia::Engine.routes.url_helpers.generic_file_path(
          @child_object
        )
      )
    else
      'unknown object'
    end
  end

  # override to check child object permissions before logging to followers
  def log_to_followers
    depositor.followers.select {|user|
      user.can?(:read, collection) && user.can?(:read, @child_object)
    }.each do |follower|
      follower.log_event(event)
    end
  end
end
