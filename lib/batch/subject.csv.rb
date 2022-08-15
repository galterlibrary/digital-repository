@csv = CSV.open('/home/deploy/all_gf_subject.csv', 'wb')
@terms =  GalterGenericFilePresenter.terms + [
  :depositor, :date_uploaded, :date_modified, :read_access_group, :id
]

header = @terms.map(&:to_s).map { |term|
  I18n.translate(:simple_form)[:labels][:generic_file][term] || term.titleize
}

header += ["Events", "Collection Ids"]

@csv << header

def add_metadata_to_csv(model)
  query = ActiveFedora::SolrService.query(
    "has_model_ssim:#{model}", { rows: 99999 }
  )

  query.each.with_index do |gf, idx|
    gfmod = gf.each.map {|k, v| [k.gsub(/_[a-z]+\z/, ''), v] }.to_h

    row = @terms.map {|term|
      t = term.to_s

      if gfmod[t].is_a?(Array)
        gfmod[t].reject(&:blank?).compact.join(' ; ')
      else
        gfmod[t].to_s
      end
    }

    record = model.constantize.find(gfmod["id"])
    event = record.events.first.blank? ? "no event" : record.events.first[:action]
    row << event
    row << record.collection_ids.reject(&:blank?).join(' ; ')

    @csv << row

    puts "#{model} Index: #{idx}" if idx % 100 == 0
  end
end

add_metadata_to_csv("GenericFile")
add_metadata_to_csv("Page")

@csv.close
