body_template = %{
PREFIX ebucore: <http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#>
DELETE {
  <> ebucore:filename "<old_filename>" .
}
INSERT {
  <> ebucore:filename "<new_filename>" .
}
WHERE { }
}

# Takes up too much memory and is too slow
#GenericFile.where('depositor_ssim' => 'institutional-pnb').each do |gf|
ActiveFedora::SolrService.query(
  'has_model_ssim:GenericFile AND depositor_ssim:institutional-pnb',
  { rows: 99999 }
).map do |gf_h|
  gf = GenericFile.find(gf_h['id'])
  old_name = gf.content.original_name
  next unless old_name =~ /xml/
  puts
  puts "Doing #{gf.id}"
  new_name = old_name.gsub(/xml/, 'pdf')
  body = body_template.gsub('<old_filename>', old_name)
                      .gsub('<new_filename>', new_name)
  url = gf.content.metadata.ldp_source.subject
  client = gf.ldp_source.client
  # This is the Ldp::Client's #patch
  # headers 'Content-Type: application/sparql-update' come from the Ldp::Client
  response = client.patch(url, body)
  raise unless response.status == 204
  gf.label = new_name
  gf.filename = [new_name]
  gf.save
end
