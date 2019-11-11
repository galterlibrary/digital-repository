require 'csv'

class CollectionMembersViewAndDownloadStats
  STAT_TYPES = ["downloads", "pageviews"]

  attr_accessor :collection, :downloads_csv_file, :pageviews_csv_file

  def initialize(collection)
    @collection = Collection.find(collection)
    @downloads_csv_file = CSV.open(
      File.join(Rails.root, "/lib/scripts/results/#{sanitize_title(@collection.title)}_downloads_stats.csv"),
      "w"
    )
    @downloads_csv_file << ["Collection Name", "File Name", "File URI", "Date", "Downloads Count"]

    @pageviews_csv_file = CSV.open(
      File.join(Rails.root, "/lib/scripts/results/#{sanitize_title(@collection.title)}_pageviews_stats.csv"),
      "w"
    )
    @pageviews_csv_file << ["Collection Name", "File Name", "File URI", "Date", "Pageviews Count"]
  end

  def sanitize_title(collection_title)
    collection_title.gsub(/[^0-9A-Z]/i, '_')
  end

  def get_stats_and_add_to_csv(type:, collection: self.collection)
    if !STAT_TYPES.include?(type)
      puts "Can only get stats for 'pageviews' or 'downloads'"
      return
    end

    file_name = "#{type}_csv_file"
    csv_file = self.send(file_name.to_sym)

    collection.members.each do |member|
      if member.class == Collection
        self.get_stats_and_add_to_csv(type: type, collection: member)
        next
      end

      file_usage = FileUsage.new(member.id)
      member_uri = "https://digitalhub.northwestern.edu/files/#{member.id}"

      month = nil
      stat_totals = {}
      file_usage.send(type.to_sym).each do |stat|
        stat_time = Time.at(stat[0]/1000)
        cmonth = "#{stat_time.month}-#{stat_time.year}"
        if month != cmonth
          stat_totals[cmonth] = stat[1]
          month = cmonth
        else
          stat_totals[cmonth] += stat[1]
        end
      end

      if csv_file.closed?
        csv_file.reopen(csv_file.path, "a")
      end

      stat_totals.each do |k,v|
        next if v.to_i == 0
        csv_file << [collection.title, member.title.first, member_uri, k, v]
      end
    end

    csv_file.close
  end
end
