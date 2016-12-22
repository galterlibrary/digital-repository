if ARGV[0].blank?
  puts 'You need to specify a user csv file to process'
  exit 1
end

$skip_ahead = ARGV[1].present?

$search_names = []
def search_names_from_elements_csv
  CSV.read(ARGV[0], headers: true).each_with_index do |u, idx|
    if $skip_ahead
      if ARGV[1].to_i == idx
        $skip_ahead = false
      else
        next
      end
    end
    last, first = u['Alphabetical name'].split(', ')
    #Multi-letter initials
    #initials = first.strip.gsub(/ +/, ' ').split(' ').map {|o| o.first }.compact.join
    #Single-letter initials
    initials = first.strip.first.to_s
    $search_names << ["#{last} #{initials}".strip, u['Username']]
  end
end

#FIXME handle with ENV variables
$auth_client = Savon.client(
  wsdl: 'http://search.webofknowledge.com/esti/wokmws/ws/WOKMWSAuthenticate?wsdl',
  basic_auth: [ENV['WOS_USER'], ENV['WOS_PASS']],
  headers: { 'SOAPAction' => '' }
)

def run_auth
  auth_response = $auth_client.call(:authenticate)
  raise unless auth_response.success?
  auth_response.http.cookies.first.name_and_value
end

def stored_auth_token
  @token ||= File.open('tmp/.wos-auth-token') do |f|
    f.read
  end
rescue Errno::ENOENT
  @token = run_auth
  File.open('tmp/.wos-auth-token', 'w') do |f|
    f.write(@token)
  end
  @token
end

def search_client(auth_token)
  Savon.client(
    wsdl: 'http://search.webofknowledge.com/esti/wokmws/ws/WokSearchLite?wsdl',
    headers: {
      'Cookie' => auth_token,
      'SOAPAction' => ''
    }
  )
end

def search_message(author_name, record_nr, record_count)
  {
    'queryParameters' => {
      'databaseId' => 'WOS',
      'userQuery' => "AU=#{author_name} AND ZP=60611",
      'queryLanguage' => 'en'
    },
    'retrieveParameters' => {
      'firstRecord' => record_nr,
      'count' => record_count
    }
  }
end

class AuthIsInvalidError < StandardError; end
def run_search(author_name, record_nr, record_count)
  message_h = search_message(author_name, record_nr, record_count)
  response = search_client(stored_auth_token).call(:search, message: message_h)
  raise AuthIsInvalidError unless response.success?

  results_h = response.body[:search_response][:return]
  [results_h[:records_found].to_i, results_h[:records]]
rescue Savon::SOAPFault
  puts 'Getting new auth token...'
  @token = nil
  File.delete('tmp/.wos-auth-token')
  retry
end

def doaj_meta(id)
  #resp = HTTParty.get("https://doaj.org/api/v1/search/articles/doi#{doi}")
  resp = HTTParty.get("https://doaj.org/api/v1/search/journals/#{id}")
  return false if resp.code != 200
  return false if resp['total'] < 1
  resp['results'].first['bibjson']
end

def wos_to_h(result_part, key)
  return { key.to_s => result_part } if result_part.is_a?(String)
  res_arr = [result_part].flatten.compact
  res_arr.inject({}) {|h, attrib|
    h[attrib[:label]] = attrib[:value]
    h
  }
end

def wos_meta(result)
  result.keys.inject({}) do |h, key|
    h[key.to_s] = wos_to_h(result[key], key)
    h
  end
end

def crossref_meta(doi)
  resp = HTTParty.get("http://api.crossref.org/works/#{doi}")
  resp = resp.code == 404 ? {} : resp['message']
  #NOTE update $static_headers if updating this
  {
    'cr:publisher' => resp['publisher'],
    #TODO change to sufia-formatted date, format example 2015-06-02T04:37:07Z
    'cr:date' => resp['created'].try(:[], 'date-time'),
    'cr:subjects' => resp['subject'],
    'cr:journal' => resp['container-title'],
  }
end

$total_processed = 0
$static_headers = ['License', 'NU Author', 'NetID', 'cr:publisher', 'cr:date', 'cr:subjects', 'cr:journal']
$all_headers = $static_headers

search_names_from_elements_csv
$open_articles = []
#$search_names = ['HUANG C']
$search_names.each do |author_name, netid|
  puts "Doing #{author_name}"
  results_count, results = run_search(author_name, 1, 0)
  if results_count == 0
    puts "No results"
    next
  end

  processed = 1
  while processed <= results_count do
    results_count, results = run_search(author_name, processed, 100)
    results = [results].flatten
    results.each do |result|
      processed += 1
      wos = wos_meta(result)
      next if wos['other']['Identifier.Doi'].blank?

      if wos['other']['Identifier.Eissn'].present?
        issn = wos['other']['Identifier.Eissn']
      else
        issn = wos['other']['Identifier.Issn']
      end

      next unless doaj = doaj_meta(issn)
      if doaj['license'].blank?
        next
      end
      if !doaj['license'].first['open_access'] && !doaj['license'].first['type'] =~ /CC /
        puts "Non-open access license: #{doaj['license'].first['type']}"
        next
      end

      cr = crossref_meta(wos['other']['Identifier.Doi'])

      $all_headers |= wos.keys.map {|key|
        wos[key].keys.map {|key2| "#{key}:#{key2}" }
      }.flatten

      $open_articles << {
        license: doaj['license'].first['type'],
        nu_author: author_name,
        netid: netid,
        wos: wos,
        cr: cr
      }
    end
  end

  $total_processed += (processed - 1)
  puts "Processed for #{author_name}: #{processed-1}"
  puts "Open-access articles: #{$open_articles.count}"
end

csv = CSV.open("tmp/wos_meta-#{Time.now.to_i}.csv", 'wb')
csv << $all_headers

csv_staff = CSV.open("tmp/wos_staff-#{Time.now.to_i}.csv", 'wb')
csv_staff << ['Title', 'Author Name', 'Author NetID', 'Journal Name',
              'License', 'Article URL', 'Staff Name']

$open_articles.each do |o|
  row = [o[:license], o[:nu_author], o[:netid]]
  row += o[:cr].values.map {|o| o.is_a?(Array) ? o.join('+') : o.to_s }
  row += $all_headers[$static_headers.count..-1].map do |h|
    level1, level2 = h.split(':')
    val = o[:wos][level1].try(:[], level2)
    val.is_a?(Array) ? val.join('+') : val.to_s
  end
  csv << row

  doi_url = "http://dx.doi.org/#{o[:wos]['other']['Identifier.Doi']}"
  csv_staff << [
    o[:wos]['title']['Title'], o[:nu_author], o[:netid],
    o[:license], o[:wos]['source']['SourceTitle'], doi_url
  ]
end

puts "All headers: #{$all_headers}"
puts "Total processed: #{$total_processed}"
