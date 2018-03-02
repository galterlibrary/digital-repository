Rails.configuration.to_prepare do
  EventJob.class_eval do
    def run
      # Log the event to the depositor's profile stream
      log_user_event

      # Fan out the event to all followers who have access
      log_to_followers

      # Notify collection subscribers
      log_for_collection_follower
    end

		def collection_event(col)
			collection_link = "<a href='/collections/#{col.id}'>#{col.title}</a>"
			collection_action = "#{action} for Collection: #{collection_link}"
			depositor.create_event(collection_action, Time.now.to_i)
		end

		def log_for_collection_follower
			return unless self.respond_to?(:generic_file)
			return unless generic_file.present?
			generic_file.collections.each do |col|
        col.followers.each do |u|
          u.log_event(collection_event(col))
        end
			end
		end
  end
end
