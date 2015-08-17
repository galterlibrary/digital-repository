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

  desc "Load LCSH names into SubjectLocalAuthorityEntry table"
  task :harvest_lcsh_names, [:file_path] => :environment do |t, args|
    puts 'This will take a long time, assumes you only have tripples with predicate == perfLabel'
    SubjectLocalAuthorityEntry.destroy_all
    entries = []
    ::RDF::Reader.open(args[:file_path], format: :ntriples) do |reader|
      reader.each_with_index do |statement, idx|
        if (idx % 3000) == 0 && (idx > 0)
          SubjectLocalAuthorityEntry.import(entries)
          entries = []
        end

        entries << SubjectLocalAuthorityEntry.new(
          lowerLabel: statement.object.to_s.downcase.slice(0..250),
          label: statement.object.to_s,
          url: statement.subject.to_s
        )
      end
    end
    SubjectLocalAuthorityEntry.import(entries) if entries.present?
  end
end

