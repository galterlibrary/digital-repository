desc "Run sufia export with InvenioRDM specific converters"
task :repo_export, [:destination] => :environment do |task, args|
  export_command = "sufia_export --verbose --models GenericFile=InvenioRdmRecordConverter,Collection=InvenioRdmCollectionConverter"
  system export_command

  if destination = args[:destination]
    system "mv tmp/export/ #{destination}"
  end
end
