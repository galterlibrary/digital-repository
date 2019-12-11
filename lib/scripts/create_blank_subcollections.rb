# Script for creating nested collections, for institutional collections.
# Creates "x" 'template' collections, adding another "y" template
# collections to each.
# To use, pass in a collection id, a number for template collections amount,
# and letter for child template collections amount. The 'letter' parameter is
# used in the form of a range, starting from 'a'. i.e. if 'letter' is 'c',
# range is a..c => a,b,c
# Example to create 10 template collections with 3 collections for each:
# current_sufia/ $ bundle exec rails runner lib/scripts/create_template_collections.rb "abc-123" 10 "c"

if ARGV.length != 3
  puts "Need collection ID, number of templates, and letter for range of "\
       "child templates!!"
  exit
end

collection_id = ARGV[0]
number_of_templates = ARGV[1].to_i
letter_range = ARGV[2].downcase

parent_collection = Collection.find(collection_id)
# Typically, institutional depositors are "institutional-collection-title"
# Utitlize `parameterize` to set the depositor name
depositor = "institutional-#{parent_collection.title.parameterize}"

number_of_templates.times do |number|
  date = Time.now.strftime("%m-%d-%y")

  template = Collection.new(
    title: "template-#{number} (#{date})",
    tag: parent_collection.tag
  )
  template.apply_depositor_metadata(parent_collection.depositor)
  template.save!

  ("a".."#{letter_range}").each do |letter|
    child = Collection.new(
      # title: "template-0a (01-01-20)"
      title: "template-#{number}#{letter} (#{date})",
      tag: parent_collection.tag
    )
    child.apply_depositor_metadata(parent_collection.depositor)
    child.save!

    template.members << child

    # because we have a before create action that sets visibility to "open"
    child.update_attributes(visibility: "restricted")
  end

  parent_collection.members << template
  parent_collection.save!

  # because we have a before create action that sets visibility to "open"
  template.visibility = "restricted"
  template.save!

  template.convert_to_institutional(
    depositor,
    parent_collection.id
  )
end
