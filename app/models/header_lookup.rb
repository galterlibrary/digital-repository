class HeaderLookup
  BASE_SPARQL_MESH_URI ="https://id.nlm.nih.gov/mesh/sparql?format=JSON&limit=10&inference=true&query=PREFIX%20rdfs"\
    "%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23%3E%0D%0APREFIX%20meshv%3A%20%3Chttp%3A%2F%2Fid.nlm."\
    "nih.gov%2Fmesh%2Fvocab%23%3E%0D%0APREFIX%20mesh2018%3A%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0A%0D%0ASELECT"\
    "%20%3Fd%20%3FdName%0D%0AFROM%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0AWHERE%20%7B%0D%0A%20%20%3Fd%20a%20"\
    "meshv%3ADescriptor%20.%0D%0A%20%20%3Fd%20rdfs%3Alabel%20%3FdName%0D%0A%20%20FILTER(REGEX(%3FdName%2C%27"
  END_SPARQL_MESH_URI = "%27%2C%20%27i%27))%20%0D%0A%7D%20%0D%0AORDER%20BY%20%3Fd%20%0D%0A"
  LCSH_BASE_URI = "http://id.loc.gov/authorities/subjects/suggest/?q="
  LCSH_ID_URI = "http://id.loc.gov/authorities/subjects/"
  MESH_ID_URI = "https://id.nlm.nih.gov/mesh/"
  MEMOIZED_MESH_FILE = "memoized_mesh.txt"
  MEMOIZED_LCSH_FILE = "memoized_lcsh.txt"
  MEMOIZED_LCNAF_FILE = "memoized_lcnaf.txt"
  SEARCHABLE_MESH_FILE = ENV['SUBJECTS_MESH_FILE']
  SEARCHABLE_LCSH_FILE = ENV['SUBJECTS_LCSH_FILE']
  SEARCHABLE_LCNAF_FILE = "subjects_lcnaf.csv"

  def initialize
    puts "initializing header_lookup..."
    # these are the terms to search through for header lookups
    @@searchable_mesh_terms ||= YAML.load_file(SEARCHABLE_MESH_FILE)
    @@searchable_lcsh_terms ||= YAML.load_file(SEARCHABLE_LCSH_FILE)
    @@searchable_lcnaf_file ||= CSV.new(SEARCHABLE_LCNAF_FILE)

    # these are values that have been previously found from the searchable terms
    @@memoized_mesh ||= read_memoized_headers(MEMOIZED_MESH_FILE)
    @@memoized_lcsh ||= read_memoized_headers(MEMOIZED_LCSH_FILE)
    @@memoized_lcnaf ||= read_memoized_headers(MEMOIZED_LCNAF_FILE)
  end

  def pid_lookup_by_scheme(term="", scheme="")
    if term.blank? || scheme.blank?
      nil
    elsif scheme == :mesh
      @@memoized_mesh[term] || mesh_term_pid_local_lookup(term) || nil
    elsif scheme == :lcsh
      @@memoized_lcsh[term] || lcsh_term_pid_local_lookup(term) || nil
    elsif scheme == :subject_name
      @@memoized_lcnaf[term] || lcnaf_pid_lookup(term) || nil
    else
      nil
    end
  end

  def mesh_term_pid_local_lookup(mesh_term="")
    puts "mesh term pid local lookup"
    @@searchable_mesh_terms.each do |term_json|
      if term_json["subject"].downcase == mesh_term.downcase.gsub("--", "/")
        mesh_id = term_json["id"]
        @@memoized_mesh[mesh_term] = mesh_id
        File.write(MEMOIZED_MESH_FILE, @@memoized_mesh)
        return mesh_id
      end
    end

    nil
  end

  def lcsh_term_pid_local_lookup(lcsh_term="")
    puts "lcsh term pid local lookup"
    @@searchable_lcsh_terms.each do |term_json|
      if term_json["subject"].downcase == lcsh_term.downcase
        lcsh_id = term_json["id"]
        @@memoized_lcsh[lcsh_term] = lcsh_id
        File.write(MEMOIZED_LCSH_FILE, @@memoized_lcsh)
        return lcsh_id
      end
    end

    nil
  end

  # return PID for provided mesh_header using SPARQL query
  def mesh_term_pid_lookup(mesh_term="")
    puts "mesh term networked lookup"
    hits = perform_and_parse_mesh_query(CGI.escape(mesh_term))

    hits.each do |hit|
      if hit["dName"]["value"].downcase == mesh_term.downcase
        mesh_pid = hit["d"]["value"].split('/').last
        mesh_id = MESH_ID_URI + mesh_pid.to_s
        @@memoized_mesh[mesh_term] = mesh_id
        File.write(MEMOIZED_MESH_FILE, @@memoized_mesh)
        return mesh_id
      end
    end

    nil
  end

  # lookup lcsh term, memoize it, write it to file, return PID
  def lcsh_term_pid_lookup(lcsh_term="")
    puts "lcsh term networked lookup"
    stripped_lcsh_term = strip_accents(lcsh_term)
    subject_names, subject_id_uris = perform_and_parse_lcsh_query(CGI.escape(stripped_lcsh_term))

    if subject_names.present? && subject_id_uris.present?
      lcsh_pid = pid_from_lcsh_hits(lcsh_term, stripped_lcsh_term, subject_names, subject_id_uris)
      lcsh_id = LCSH_ID_URI + lcsh_pid.to_s
      @@memoized_lcsh[lcsh_term] = lcsh_id
      File.write(MEMOIZED_LCSH_FILE, @@memoized_lcsh)
      lcsh_id
    else
      nil
    end
  end

  def lcnaf_pid_lookup(lcnaf_term)
    lcnaf_term = lcnaf_term.downcase.strip

    @@searchable_lcnaf_file.each do |row|
      term, pid = row

      # if the term matches up memoize, write to file, and return pid
      if lcnaf_term == term.downcase.strip
        @@memoized_lcnaf[lcnaf_term] = pid
        File.write(MEMOIZED_LCNAF_FILE, @@memoized_lcnaf)
        return pid
      end
    end

    # if no pid is found, return nil
    nil
  end

  private

  def perform_and_parse_lcsh_query(stripped_lcsh_term)
    # perform search with lcsh_term's whitespace replaced with '*' character
    query_result = HTTParty.get(LCSH_BASE_URI + "*#{stripped_lcsh_term.gsub(/\s/,'*')}*")
    hits = JSON.parse(query_result)

    subject_names = hits.try(:[], 1)
    subject_id_uris = hits.try(:[], -1)

    return subject_names, subject_id_uris
  end

  def pid_from_lcsh_hits(lcsh_term, stripped_lcsh_term, subject_names, subject_id_uris)
    # for multiple matches in a search find the exact match index...
    subject_match_index = subject_names.index{ |name| name == lcsh_term || name = stripped_lcsh_term }
    # ...then use that index ith the subject_id_uris array to get the pid
    subject_id_uris[subject_match_index].split('/').last
  end

  def perform_and_parse_mesh_query(mesh_term)
    query_result = HTTParty.get(BASE_SPARQL_MESH_URI + mesh_term + END_SPARQL_MESH_URI)
    json_parsed_result = JSON.parse(query_result)
    json_parsed_result.try(:[], "results").try(:[], "bindings")
  end

  def strip_accents(term="")
    # normalize with unicode normalization form kd, replace anything that
    # is not a space, dash, parentheses, or ascii character with empty string
    term.mb_chars.normalize(:kd).gsub(/[^\ \-()x00-\x7F]/n, '').to_s
  end

  # read memoized from file, if no file found return blank hash
  def read_memoized_headers(filepath)
    begin
      file = File.read(filepath)
      # eval will interpret a ruby string passed as an argument
      # in this case it constructs a hash from the file
      eval(file)
    rescue Errno::ENOENT
      return {}
    end
  end
end
