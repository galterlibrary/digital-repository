def find_subject(pref_label_json)
  if pref_label_json.is_a? Hash
    subject = pref_label_json["@value"]
  elsif pref_label_json.is_a? Array
    subject = pref_label_json.find{ |v| v.is_a? String }
  elsif pref_label_json.is_a? String
    subject = pref_label_json
  else
    # if you end up here you are probably going to want to see why
    # binding.pry
    print pref_label_json
    raise "#find_subject found an unexpected value, stopping here"
  end

  subject&.gsub('"', '\\"')
end

# lcsh subject headings with SKOS/RDF formatted into ndjson
lcsh_file = open("lcsh.skos.ndjson")
lcsh_yaml_file = open("subjects_lcsh.yml", "w")
memoized_ids = Set.new

lcsh_file.each_line do |line|
  line_graph_json = JSON(line)["@graph"]

  line_graph_json.each do |node|
    if node["@type"] == "skos:Concept" && node["skos:prefLabel"].present?
      id = node["@id"]

      if !memoized_ids.include?(id)
        memoized_ids << id
        lcsh_string = %(- id: #{id}\n  scheme: LCSH\n  subject: "#{find_subject(node["skos:prefLabel"])}"\n)
        lcsh_yaml_file << lcsh_string
      end
    end
  end
end
