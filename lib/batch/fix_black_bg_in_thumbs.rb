ActiveFedora::SolrService.query(
  'mime_type_tesim:pdf', { rows: 99999 }
).map do |gf_h|
  gf = GenericFile.find(gf_h['id'])
  puts "Doing #{gf.id}"
  gf.create_derivatives
  # To invalidate cache
  gf.mark_as_changed(:label)
  gf.save
end
