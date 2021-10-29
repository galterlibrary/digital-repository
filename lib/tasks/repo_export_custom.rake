desc "Run custom export with InvenioRDM specific converters"

task :repo_export_custom, :environment do #|task, args|
  puts "---------\nBeginning repo export at #{Time.now} #{Time.zone}\n---------"

  # set classes to use for export
  record_converter = {model_class: GenericFile, converter_class: InvenioRdmRecordConverter}
  collection_converter = {model_class: "", converter_class: ""}

  # validate classes
  [record_converter, collection_converter].each do |converter|
    puts "---------\nValidating converter classes\n---------"
    raise(RegistryError, "Model (#{model_class.name}) for conversion must be an ActiveFedora::Base") unless converter[:model_class].ancestors.include?(ActiveFedora::Base)
    # raise(RegistryError, "Converter (#{converter_class.name}) for conversion must be an Sufia::Export::Converter") unless converter[:converter_class].ancestors.include?(Sufia::Export::Converter)
  end

  puts "---------\nBeginning file export at #{Time.now} #{Time.zone}\n---------"
  generic_file_conversion_count = 0
  GenericFile.all.each do |gf|
    converted_record_object = InvenioRdmRecordConverter.new(gf)

    puts "---------\nFile has id: #{gf.id}\n---------"
    file_path = "tmp/export/#{record_converter[:model_class].name.underscore}_#{gf.id}.json"
    File.write(file_path, converted_record_object.to_json(pretty: true))

    # increment and put object out of scope
    generic_file_conversion_count += 1
    converted_record_object = nil
  end
  puts "---------\nCompleted file export at #{Time.now} #{Time.zone}\n---------"

  # TODO: Implement collection conversion
  collection_conversion_count = 0
  # Collection.all.each do |collection|
  #   converted_collection_object = InvenioRdmCollectionConverter.new(collection)
  #   file_name = "tmp/export/#{collection.id}.json"
  #
  #   File.write(file_name, converted_collection_object.to_json)
  #   collection_conversion_count += 1
  # end
  #
  puts "---------\nCompleted repo export at #{Time.now} #{Time.zone}\n---------"
  puts "---------\nExported #{generic_file_conversion_count} files\n#{collection_conversion_count} collections\n---------"
end
