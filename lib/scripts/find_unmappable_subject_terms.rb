# Load each memoized file, pass filepaths as argument
# # Because the terms are the keys, just take that value would return the full id
# # Set is faster than array for lookups
lcsh_filepath = ARGV[0]
mesh_filepath = ARGV[1]

memoized_lcsh_terms = Set.new(eval(File.read(lcsh_filepath)).keys)
memoized_mesh_terms = Set.new(eval(File.read(mesh_filepath)).keys)

missing_lcsh_terms = Set.new
missing_mesh_terms = Set.new

GenericFile.all.each do |gf|
  gf.lcsh&.each do |lcsh_term|
    if !memoized_lcsh_terms.include?(lcsh_term)
      missing_lcsh_terms << lcsh_term
    end
  end

  gf.mesh&.each do |mesh_term|
    if !memoized_mesh_terms.include?(mesh_term)
      missing_mesh_terms << mesh_term
    end
  end
end

File.open("missing_lcsh_terms.csv", "w") { |f| missing_lcsh_terms.each{ |lcsh_term| f.puts(lcsh_term) } }
File.open("missing_mesh_terms.csv", "w") { |f| missing_mesh_terms.each{ |mesh_term| f.puts(mesh_term) } }
