namespace :rdf do
  # After a successful load you should be able to access term list via:
  #   /authorities/#{model_name}/#{authority_name}?q=#{query}
  # @param auth_name [String] containing the name of the authority, and
  #   so the name to use when calling the authorities url, for example
  #   /authorities/model_name/#{auth_name}?q=
  # @param file_path [String], path to file containing tripples
  # @param predicate [String] default ::RDF::SKOS.prefLabel, valid rdf predicate
  # @param model [String] defalt 'generic_files', name to use in DomainTerm
  #   table entry and when calling the authorities url, for example
  #   /authorities/#{model}/authority_name?q=
  # Example of loading an ISO639 file from http://id.loc.gov/download/:
  #   rake rdf:harvest_skos['language','/home/phb010/Downloads/iso6391.nt','RDF::Vocab::MADS.authoritativeLabel']
  desc "Load terms from and RDF skos file into the LocalAuthorityEntry table"
  task :harvest_skos, [:auth_name, :file_path, :predicate, :model] => :environment do |t, args|
    puts 'This can take a long time, depending on the number of terms in the file'
    opts = {}
    opts[:predicate] = eval(args[:predicate].to_s) if args[:predicate].present?
    if local = LocalAuthority.find_by(name: args[:auth_name])
      local.local_authority_entries.destroy_all
      local.destroy
    end
    LocalAuthority.harvest_rdf(args[:auth_name], [args[:file_path]], opts)
    model = args[:model] || 'generic_files'
    LocalAuthority.register_vocabulary(model, args[:auth_name], args[:auth_name])
  end
end
