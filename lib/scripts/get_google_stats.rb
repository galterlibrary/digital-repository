require 'csv'
dstats = CSV.open("/home/deploy/download_stats.csv", "w")
dstats << ['File name', 'Date', 'Download Count', 'File URI', 'Collection Name']
vstats = CSV.open("/home/deploy/view_stats.csv", "w")
vstats << ['File name', 'Date', 'View Count', 'File URI', 'Collection Name']

col = Collection.find('2cc92425-b656-47ea-a3b4-825405ee6088')
#ss.members.each do |col|
  col.members.each do |gf|
    fu = FileUsage.new(gf.id)
    furi = "https://digitalhub.northwestern.edu/files/#{gf.id}"

    month = nil
    vtotals = {}
    fu.pageviews.each do |v|
      vtime = Time.at(v[0]/1000)
      cmonth = "#{vtime.month}-#{vtime.year}"
      if month != cmonth
        vtotals[cmonth] = v[1]
        month = cmonth
      else
        vtotals[cmonth] += v[1]
      end
    end

    vtotals.each do |k, v|
      next if v.to_i == 0
      vstats << [gf.title.first, k, v, furi, col.title]
    end

    month = nil
    dtotals = {}
    fu.downloads.each do |v|
      dtime = Time.at(v[0]/1000)
      cmonth = "#{dtime.month}-#{dtime.year}"
      if month != cmonth
        dtotals[cmonth] = v[1]
        month = cmonth
      else
        dtotals[cmonth] += v[1]
      end
    end

    dtotals.each do |k, v|
      next if v.to_i == 0
      dstats << [gf.title.first, k, v, furi, col.title]
    end
  end
#end

dstats.close
vstats.close
