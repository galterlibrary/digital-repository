class HeaderLookup
  MEMOIZED_MESH_FILE = "memoized_mesh.txt"
  MEMOIZED_LCSH_FILE = "memoized_lcsh.txt"
  MEMOIZED_LCNAF_FILE = "memoized_lcnaf.txt"

  SEARCHABLE_MESH_FILE = "subjects_mesh.jsonl"
  SEARCHABLE_LCSH_FILE = "subjects_lcsh.jsonl"
  # Needs to be in config because file is too large for VCS
  SEARCHABLE_LCNAF_FILE = ENV["SUBJECTS_LCNAF"]

  ABSENT_SUBJECT = :absent

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
    searchable_file = ""

    # assign searchable file,  memoized terms, any string modifications
    if term.blank? || field.blank?
      return nil
    elsif field == :mesh
      searchable_file = @@searchable_mesh_file
      memoized_terms = @@memoized_mesh
      memoized_file = MEMOIZED_MESH_FILE
      term = term.gsub("--", "/")
    elsif field == :lcsh
      searchable_file = @@searchable_lcsh_file
      memoized_terms = @@memoized_lcsh
      memoized_file = MEMOIZED_LCSH_FILE
    elsif field == :subject_name || field == :subject_geographic
      searchable_file = @@searchable_lcnaf_file
      memoized_terms = @@memoized_lcnaf
      memoized_file = MEMOIZED_LCNAF_FILE
    else
      return nil
    end

    # check for memoized term
    if memoized_terms[term]
      term_pid = memoized_terms[term]
    # search
    else
      term_pid = ABSENT_SUBJECT

      File.foreach(searchable_file) do |line|
        term_json = JSON.parse(line)

        if term_json["subject"].downcase == term.downcase
          term_pid = term_json["id"]
          break
        end
      end

      memoized_terms[term] = term_pid
      File.write(memoized_file, memoized_terms)
    end

    term_pid == ABSENT_SUBJECT ? nil : term_pid
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
