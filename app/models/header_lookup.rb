class HeaderLookup
  MEMOIZED_MESH_FILE = "memoized_mesh.json"
  MEMOIZED_LCSH_FILE = "memoized_lcsh.json"
  MEMOIZED_LCNAF_FILE = "memoized_lcnaf.json"

  SEARCHABLE_MESH_FILE = "subjects_mesh.jsonl"
  SEARCHABLE_LCSH_FILE = "subjects_lcsh.jsonl"
  # Needs to be in config because file is too large for VCS
  SEARCHABLE_LCNAF_FILE = ENV["SUBJECTS_LCNAF"]

  ABSENT_SUBJECT = "absent"

  def initialize
    # these are the terms to search through for header lookups
    @@searchable_mesh_file ||= SEARCHABLE_MESH_FILE
    @@searchable_lcsh_file ||= SEARCHABLE_LCSH_FILE
    @@searchable_lcnaf_file ||= SEARCHABLE_LCNAF_FILE

    # these are values that have been previously found from the searchable terms
    @@all_memoized_terms = {
      mesh: read_memoized_headers(MEMOIZED_MESH_FILE),
      lcsh: read_memoized_headers(MEMOIZED_LCSH_FILE),
      lcnaf: read_memoized_headers(MEMOIZED_LCNAF_FILE)
    }
  end

  def pid_lookup_by_field(term="", field="")
    searchable_file = ""

    # assign searchable file,  memoized terms, any string modifications
    if term.blank? || field.blank?
      return nil
    elsif field == :mesh
      searchable_file = @@searchable_mesh_file
      memoized_vocab = :mesh
      memoized_file = MEMOIZED_MESH_FILE
      term = term.gsub("--", "/")
    elsif field == :lcsh
      searchable_file = @@searchable_lcsh_file
      memoized_vocab = :lcsh
      memoized_file = MEMOIZED_LCSH_FILE
    elsif field == :subject_name || field == :subject_geographic
      searchable_file = @@searchable_lcnaf_file
      memoized_vocab = :lcnaf
      memoized_file = MEMOIZED_LCNAF_FILE
    else
      return nil
    end

    # check for memoized term
    term_pid = search_memoized_terms(term, memoized_vocab)

    # search
    if term_pid.blank?
      term_pid = ABSENT_SUBJECT

      File.foreach(searchable_file) do |line|
        term_json = JSON.parse(line)

        if term_json["subject"].downcase == term.downcase
          term_pid = term_json["id"]
          break
        end
      end

      @@all_memoized_terms[memoized_vocab][term] = term_pid

      File.write(memoized_file, JSON.pretty_generate(@@all_memoized_terms[memoized_vocab]))
    end

    term_pid == ABSENT_SUBJECT ? nil : term_pid
  end

  private

  def search_memoized_terms(term, primary_memoized_vocab)
    secondary_memoized_vocab = @@all_memoized_terms.keys - [primary_memoized_vocab]
    ordered_memoized_vocabs = [primary_memoized_vocab] + secondary_memoized_vocab

    # if the term can't be found in the vocab assigned to the field, check the other memoized files
    ordered_memoized_vocabs.each do |memoized_vocab|
      if term_pid = @@all_memoized_terms[memoized_vocab][term]
        return term_pid
      end
    end

    # nothing has been found in ANY memoized file
    nil
  end

  def read_memoized_headers(filepath)
    JSON.parse(File.read(filepath))
  end
end
