require 'csv'

funding_csv = CSV.read("prod_funding_sources.csv")
funding_csv.shift
formatted_funding_data = funding_csv.each_with_object({}) do |row, hash|
  # name, ror-identifier, award-number, file-id
  name = row[0]
  identifier = row[1]
  award_number = row[2]
  file_id = row[3]

  if hash.keys.include?(file_id)
    hash[file_id] +=
      [{
        "funder": {
          "name": "#{name}",
          "identifier": "#{identifier}",
          "scheme": "ror"
        },
        "award": {
          "title": "", # always blank
          "number": "#{award_number}",
          "identifier": "", # always blank
          "scheme": "" # always blank
        }
      }]
  else
    hash[file_id] =
      [{
        "funder": {
          "name": "#{name}",
          "identifier": "#{identifier}",
          "scheme": "ror"
        },
        "award": {
          "title": "", # always blank
          "number": "#{award_number}",
          "identifier": "", # always blank
          "scheme": "" # always blank
        }
      }]
  end
end

File.write("app/models/concerns/galtersufia/generic_file/funding_data.txt", formatted_funding_data)
