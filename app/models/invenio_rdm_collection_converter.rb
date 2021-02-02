include Sufia::Export

# Convert a Collection including metadata, permissions and version metadata into a PORO
# so that the metadata can be exported in json format using to_json
#
class InvenioRdmCollectionConverter < Sufia::Export::Converter
  # Create an instance of a InvenioRdmCollectionConverter converter containing all the metadata for json export
  #
  # @param [collection] collection file to be converted for export
  def initialize(collection)
    @id = collection.id
    # @title = collection.title
    # @description = collection.description
    # @creator = collection.creator.map { |c| c }
    # @members = collection.members.map(&:id)
    # @permissions = permissions(collection)
  end
end
