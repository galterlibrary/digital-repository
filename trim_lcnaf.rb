require 'csv'
require 'json'

CSV.open("subjects_lcnaf.csv", "wb") do |lcnaf_csv|
  File.open("lcnaf.skos.ndjson").each_line do |line|
    line_hash = JSON.parse(line)
    id = line_hash["@context"]["about"]
    term = ""
    graph = line_hash["@graph"]

    graph.each do |graph_entry|
      if graph_entry["@type"] == "skos:Concept"
        term = graph_entry["skos:prefLabel"]
      elsif graph_entry["@type"] == "skosxl:Label"
        term = graph_entry["skosxl:literalForm"]
      end

      if !term.empty?
        lcnaf_csv << [term, id]
        break
      end
    end
  end
end
