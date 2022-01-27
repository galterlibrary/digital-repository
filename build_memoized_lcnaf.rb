header_lookup = HeaderLookup.new

GenericFile.all.each do |generic_file|
  lcnaf_terms = generic_file.tag

  if lcnaf_terms.blank?
    next
  else
    lcnaf_terms.each{ |term| header_lookup.pid_lookup_by_scheme(term, :tag) }
  end
end
