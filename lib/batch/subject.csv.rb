csv = CSV.open('/home/deploy/all_gf_subject.csv', 'wb')
terms =  GalterGenericFilePresenter.terms + [
  :depositor, :date_uploaded, :date_modified, :read_access_group, :isPartOf, :id
]

csv << terms.map(&:to_s).map { |term|
  I18n.translate(:simple_form)[:labels][:generic_file][term] || term.to_s.titleize
}

ActiveFedora::SolrService.query('has_model_ssim:GenericFile', { rows: 99999 }).each.with_index do |gf, idx|
  gfmod = gf.each.map {|k, v| [k.gsub(/_[a-z]+\z/, ''), v] }.to_h
  csv << terms.map {|term|
    t = term.to_s
    (gfmod[t].is_a?(Array) ? gfmod[t].reject(&:blank?).compact.join(' ; ') : gfmod[t]).to_s
  }
  puts "Index: #{idx}" if idx % 100 == 0
end
ActiveFedora::SolrService.query('has_model_ssim:Page', { rows: 99999 }).each.with_index do |gf, idx|
  gfmod = gf.each.map {|k, v| [k.gsub(/_[a-z]+\z/, ''), v] }.to_h
  csv << terms.map {|term|
    t = term.to_s
    (gfmod[t].is_a?(Array) ? gfmod[t].reject(&:blank?).compact.join(' ; ') : gfmod[t]).to_s
  }
  puts "Index: #{idx}" if idx % 100 == 0
end
csv.close
