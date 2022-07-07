class HeaderLookup
  LCSH_BASE_URI = "http://id.loc.gov/authorities/subjects/suggest/?q="
  LCSH_ID_URI = "http://id.loc.gov/authorities/subjects/"
  MESH_ID_URI = "https://id.nlm.nih.gov/mesh/"

  MEMOIZED_MESH_FILE = "memoized_mesh.txt"
  MEMOIZED_LCSH_FILE = "memoized_lcsh.txt"
  MEMOIZED_LCNAF_FILE = "memoized_lcnaf.txt"

  SEARCHABLE_LCNAF_FILE = "subjects_lcnaf.jsonl"
  SEARCHABLE_MESH_FILE = 'subjects_mesh.jsonl'
  SEARCHABLE_LCSH_FILE = 'subjects_lcsh.jsonl'

  ABSENT_SUBJECT = :absent

  def initialize
    # these are the terms to search through for header lookups
    @@searchable_mesh_file ||= SEARCHABLE_MESH_FILE
    @@searchable_lcsh_file ||= SEARCHABLE_LCSH_FILE
    @@searchable_lcnaf_file ||= SEARCHABLE_LCNAF_FILE

    # these are values that have been previously found from the searchable terms
    @@memoized_mesh ||= read_memoized_headers(MEMOIZED_MESH_FILE)
    @@memoized_lcsh ||= read_memoized_headers(MEMOIZED_LCSH_FILE)
    @@memoized_lcnaf ||= read_memoized_headers(MEMOIZED_LCNAF_FILE)
  end

  def pid_lookup_by_field(term="", field="")
    if term.blank? || field.blank?
      nil
    elsif field == :mesh
      @@memoized_mesh[term] || mesh_term_pid_local_lookup(term) || nil
    elsif field == :lcsh
      @@memoized_lcsh[term] || lcsh_term_pid_local_lookup(term) || nil
    elsif field == :subject_name || field == :subject_geographic
      pid = @@memoized_lcnaf[term] || lcnaf_pid_lookup(term)

      if pid == ABSENT_SUBJECT
        nil
      else
        pid
      end
    else
      nil
    end
  end

  def mesh_term_pid_local_lookup(mesh_term="")
    File.foreach(@@searchable_mesh_file) do |line|
      mesh_term_json = JSON.parse(line)

      if mesh_term_json["subject"].downcase == mesh_term.downcase.gsub("--", "/")
        mesh_id = mesh_term_json["id"]
        @@memoized_mesh[mesh_term] = mesh_id
        File.write(MEMOIZED_MESH_FILE, @@memoized_mesh)
        return mesh_id
      end
    end

    nil
  end

  def lcsh_term_pid_local_lookup(lcsh_term="")
    File.foreach(@@searchable_lcsh_file) do |line|
      lcsh_term_json = JSON.parse(line)

      if lcsh_term_json["subject"].downcase == lcsh_term.downcase
        lcsh_id = lcsh_term_json["id"]
        @@memoized_lcsh[lcsh_term] = lcsh_id
        File.write(MEMOIZED_LCSH_FILE, @@memoized_lcsh)
        return lcsh_id
      end
    end

    nil
  end

  def lcnaf_pid_lookup(lcnaf_term="")
    lcnaf_id = ABSENT_SUBJECT

    File.foreach(@@searchable_lcnaf_file) do |line|
      lcnaf_term_json = JSON.parse(line)

      if lcnaf_term_json["subject"].downcase == lcnaf_term.downcase
        lcnaf_id = lcnaf_term_json["id"]
        break
      end
    end

    @@memoized_lcnaf[lcnaf_term] = lcnaf_id
    File.write(MEMOIZED_LCNAF_FILE, @@memoized_lcnaf)
    lcnaf_id
  end

  private

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
