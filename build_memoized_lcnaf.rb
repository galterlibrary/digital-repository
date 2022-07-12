header_lookup = HeaderLookup.new
lcnaf_terms = Set.new

# Build the set of terms
GenericFile.all.each do |generic_file|
  generic_file.subject_name.each{ |sub_name| lcnaf_terms << sub_name }
  generic_file.subject_geographic.each{ |sub_geo| lcnaf_terms << sub_geo }
end

# Run the lookup on the set of terms to build the cache
lcnaf_terms.each{ |term| header_lookup.lcnaf_pid_lookup(term) }
