Rails.configuration.to_prepare do
  EventJob.class_eval do
    def run
      # Log the event to the depositor's profile stream
      log_user_event

      # Fan out the event to all followers who have access
      log_to_followers

      # Notify collection subscribers
      if self.respond_to?(:generic_file)
        log_for_collection_follower(generic_file)
      elsif self.respond_to?(:collection)
        log_for_collection_follower(collection)
      end
    end

    def collection_event(col)
      collection_link = "<a href='/collections/#{col.id}'>#{col.title}</a>"
      collection_action = "#{action} for Collection: #{collection_link}"
      depositor.create_event(collection_action, Time.now.to_i)
    end

    def log_to_all_followers(col, obj, object_removal=false)
      col.followers.each do |user|
        if !object_removal
          next unless user.can?(:read, obj)
        end
        
        next unless user.can?(:read, col)
        
        user.log_event(collection_event(col)) if !col.collections.map { |o| o.followers }.flatten.include?(user)
      end
    end

    def log_for_collection_follower(obj)
      return unless obj.present?
      obj.collections.each do |col|
        log_to_all_followers(col, obj)
      end
    end
  end
end
