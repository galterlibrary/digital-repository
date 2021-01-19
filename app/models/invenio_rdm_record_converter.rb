include Sufia::Export

# Convert a GenericFile including metadata, permissions and version metadata into a PORO
# so that the metadata can be exported in json format using to_json
#
class InvenioRdmRecordConverter < Sufia::Export::Converter
  include Galtersufia::GenericFile::InvenioResourceTypeMappings
  include Galtersufia::GenericFile::KnownOrganizations

  # Create an instance of a InvenioRdmRecordConverter converter containing all the metadata for json export
  #
  # @param [GenericFile] generic_file file to be converted for export
  def initialize(generic_file=nil)
    return unless generic_file

    #PIDs
    @pids = invennio_pids(generic_file.doi.shift)
    @metadata = invenio_metadata(generic_file)
    @provenance = invenio_provenance(generic_file.proxy_depositor, generic_file.on_behalf_of)
    # @label = generic_file.label
    # @depositor = generic_file.depositor
    # @arkivo_checksum = generic_file.arkivo_checksum
    # @relative_path = generic_file.relative_path
    # @import_url = generic_file.import_url
    # @resource_type = generic_file.resource_type
    # @title = generic_file.title
    # @creator = generic_file.creator
    # @contributor = generic_file.contributor
    # @description = generic_file.description
    # @tag = generic_file.tag
    # @rights = generic_file.rights
    # @publisher = generic_file.publisher
    # @date_created = generic_file.date_created
    # @date_uploaded = generic_file.date_uploaded
    # @date_modified = generic_file.date_modified
    # @subject = generic_file.subject
    # @language = generic_file.language
    # @identifier = generic_file.identifier
    # @based_near = generic_file.based_near
    # @related_url = generic_file.related_url
    # @bibliographic_citation = generic_file.bibliographic_citation
    # @source = generic_file.source
    # @batch_id = generic_file.batch.id if generic_file.batch
    # @visibility = generic_file.visibility
    # @versions = versions(generic_file)
    # @permissions = permissions(generic_file)
  end

  private

  def versions(gf)
    return [] unless gf.content.has_versions?
    Sufia::Export::VersionGraphConverter.new(gf.content.versions).versions
  end

  def invennio_pids(doi)
    {
      "doi": {
        "identifier": doi, # doi is stored in an array
        "provider": "datacite",
        "client": "digitalhub"
      }
    }
  end

  def invenio_provenance(proxy_depositor, on_behalf_of)
    {
      "created_by": {
        "user": proxy_depositor
      },
      "on_behalf_of": {
        "user": on_behalf_of
      }
    }
  end

  def invenio_metadata(gf)
    {
      "resource_type": resource_type(gf.resource_type.shift),
      "creators": creators(gf.creator)
    }
  end


  def resource_type(digitalhub_subtype)
    irdm_subtype = DH_RESOURCE_TYPES[digitalhub_subtype]
    irdm_type = IRDM_RESOURCE_TYPES[irdm_subtype]

    {
      "type": irdm_type,
      "subtype": irdm_subtype
    }
  end

  def creators(creators)
    creators.map do |creator|
      # Galter Health Sciences Library is a User on production DigitalHub, but it does NOT have a formal_name value
      dh_user = User.find_by(formal_name: creator)

      # organization
      if organization?(creator)
        name = creator
        creator_type = "organisational"
        family_name = ""
        given_name = ""
        identifiers = {}
        affiliations = [] # only used for creator_type "personal"
      # user
      elsif dh_user.present?
        name = dh_user.formal_name # will always be this regardless of type
        creator_type = "personal"
        dh_user_display_name = dh_user.display_name.split(' ') # split name into components to be reused
        family_name = dh_user_display_name.pop # remove last value from display name
        given_name = dh_user_display_name.join(' ') # the remaining strings becomes given name
        identifiers = dh_user.orcid.present? ? {"orcid": dh_user.orcid.split('/').pop} : {}
        affiliations = [] # TODO: user.affiliation is nil for all users on production... where do we get this value?
      # TODO: unknown personal, what do we enter for these fields?
      else
        name = creator
        creator_type = "personal"
        family_name = ""
        given_name = ""
        identifiers = {}
        affiliations = [] # TODO: user.affiliation is nil for all users on production... where do we get this value?
      end

      {
        "name": name.include?("not identified") ? "" : creator,
        "type": creator_type,
        "role": "",
        "given_name": given_name,
        "family_name": family_name,
        "identifiers": identifiers, # TODO: where can we find additional identifiers?
        "affiliations": affiliations
      }
    end
  end

  def format_creator_names(creator_name)
    family_name = creator_name.pop # remove last value from display name
    given_name = creator_name.join(' ') # the remaining strings becomes given name
  end
end
