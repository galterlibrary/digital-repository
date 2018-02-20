Rails.configuration.to_prepare do
  require 'sufia/models/stats/user_stat_importer'
  Sufia::UserStatImporter.class_eval do
    # Galter overrides this because we don't want institutional
    # depositors with huge amounts of stats to be included.
    def sorted_users
      users = []
      ::User.where('username not like ?', 'institutional%').find_each do |user|
        users.push(self.class::UserRecord.new(user.id, user.user_key, date_since_last_cache(user)))
      end
      users.sort { |a, b| a.last_stats_update <=> b.last_stats_update }
    end
  end
end
