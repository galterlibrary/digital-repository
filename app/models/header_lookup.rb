class HeaderLookup
  BASE_SPARQL_MESH_URI ="https://id.nlm.nih.gov/mesh/sparql?format=JSON&limit=10&inference=true&query=PREFIX%20rdfs"\
    "%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23%3E%0D%0APREFIX%20meshv%3A%20%3Chttp%3A%2F%2Fid.nlm."\
    "nih.gov%2Fmesh%2Fvocab%23%3E%0D%0APREFIX%20mesh2018%3A%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0A%0D%0ASELECT"\
    "%20%3Fd%20%3FdName%0D%0AFROM%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0AWHERE%20%7B%0D%0A%20%20%3Fd%20a%20"\
    "meshv%3ADescriptor%20.%0D%0A%20%20%3Fd%20rdfs%3Alabel%20%3FdName%0D%0A%20%20FILTER(REGEX(%3FdName%2C%27"
  END_SPARQL_MESH_URI = "%27%2C%20%27i%27))%20%0D%0A%7D%20%0D%0AORDER%20BY%20%3Fd%20%0D%0A"
  LCSH_BASE_URI = "http://id.loc.gov/authorities/subjects/suggest/?q="
  MEMOIZED_MESH_FILE = "memoized_mesh.txt"
  MEMOIZED_LCSH_FILE = "memoized_lcsh.txt"

  def initialize(memoized_mesh_file_path=MEMOIZED_MESH_FILE, memoized_lcsh_file_path=MEMOIZED_LCSH_FILE)
    @@memoized_mesh ||= read_memoized_headers(memoized_mesh_file_path)
    @@memoized_lcsh ||= read_memoized_headers(memoized_lcsh_file_path)
  end

  def pid_lookup_by_scheme(term="", scheme="")
    if term.blank? || scheme.blank?
      return
    elsif scheme == :mesh
      @@memoized_mesh[term] || mesh_term_pid_lookup(term)
    elsif scheme == :lcsh
      @@memoized_lcsh[term] || lcsh_term_pid_lookup(term)
    else
      return
    end
  end

  # return PID for provided mesh_header using SPARQL query
  def mesh_term_pid_lookup(mesh_term="")
    hits = perform_and_parse_mesh_query(mesh_term)

    if hits.present?
      mesh_pid = pid_from_mesh_hits(hits)
      @@memoized_mesh[mesh_term] = mesh_pid
      File.write(MEMOIZED_MESH_FILE, @@memoized_mesh)
      mesh_pid
    else
      nil
    end
  end

  # lookup lcsh term, memoize it, write it to file, return PID
  def lcsh_term_pid_lookup(lcsh_term="")
    stripped_lcsh_term = strip_accents(lcsh_term)
    subject_names, subject_id_uris = perform_and_parse_lcsh_query(stripped_lcsh_term)

    if subject_names.present? && subject_id_uris.present?
      lcsh_pid = pid_from_lcsh_hits(lcsh_term, stripped_lcsh_term, subject_names, subject_id_uris)
      @@memoized_lcsh[lcsh_term] = lcsh_pid
      File.write(MEMOIZED_LCSH_FILE, @@memoized_lcsh)
      lcsh_pid
    else
      nil
    end
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
    # puts "pid_from_lcsh_hits: " + lcsh_term
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

  def pid_from_mesh_hits(id_uris)
    # take the first match found, split it's URI to get the PID at the end
    id_uris.shift["d"]["value"].split('/').last
  end

  def strip_accents(term="")
    # normalize with unicode normalization form kd, replace anything that
    # is not a space, dash, parentheses, or ascii character with empty string
    term.mb_chars.normalize(:kd).gsub(/[^\ \-()x00-\x7F]/n, '').to_s
  end

  # read memoized from JSON file, if no file found return blank hash
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
