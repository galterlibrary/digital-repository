# Before you run this script empty the directory tmp/export/!
#   rm -rf tmp/export/; mkdir tmp/export/
# Run this script with the following:
#   ./bin/rails r lib/scripts/repo_export_in_batches.rb > "$(date +'%Y-%m-%d-%H%M%S')_repo_export_in_batches.log"
# OR
#   rm -rf tmp/export/; mkdir tmp/export/; ./bin/rails r lib/scripts/repo_export_in_batches.rb > "$(date +'%Y-%m-%d-%H%M%S')_repo_export_in_batches.log"
#
puts "---------\nBeginning repo export at #{Time.now} #{Time.zone}\n---------"

# set classes to have records exported and classes that will do the actual conversion
generic_file_converter = {model_class: GenericFile, converter_class: InvenioRdmRecordConverter}
collection_converter = {model_class: "", converter_class: ""}
# TODO: Implement collection conversion
converters = [generic_file_converter]

# validate classes
puts "---------\nValidating converter classes\n---------"
converters.each do |converter|
  raise(RegistryError, "Model (#{converter[:model_class].name}) for conversion must be an ActiveFedora::Base") unless converter[:model_class].ancestors.include?(ActiveFedora::Base)
end

puts "---------\nCreating Collection Store\n---------"
collection_store = CollectionStore.new
collection_store.build_collection_store_data
collection_store.build_paths_for_collection_store

puts "---------\nCreating Role Store\n---------"
role_store = RoleStore.new
role_store.build_role_store_data

conversion_counts = {}
# for each converter
converters.each do |converter|
  puts "---------\nBeginning #{converter[:model_class].to_s} export at #{Time.now} #{Time.zone}\n---------"
  conversion_count = 0

  converter[:model_class].find_each do |record_for_export|
    converted_record = converter[:converter_class].new(
      record_for_export, collection_store.data, role_store.data
    )
    puts "---------\n#{converter[:model_class].name} has id: #{record_for_export.id}\n---------"

    if converted_record.present?
      file_path = "tmp/export/#{converter[:model_class].name.underscore}_#{record_for_export.id}.json"
      File.write(file_path, converted_record.to_json(pretty: true))
    end

    conversion_count += 1
  end

  conversion_counts.merge({converter[:model_class].to_s => conversion_count})
  puts "---------\nCompleted #{converter[:model_class].to_s} export at #{Time.now} #{Time.zone}\n with #{conversion_count} records exported\n---------"
end

puts "---------\nCreating Role Data File\n---------"
role_data_file_path = "tmp/export/role_data.json"
File.write(role_data_file_path , JSON.pretty_generate(role_store.data))

puts "---------\nCompleted repo export at #{Time.now} #{Time.zone}\n---------"
conversion_counts.each do |model_name, conversion_count|
  puts "Exported #{conversion_count} #{model_name}"
end
