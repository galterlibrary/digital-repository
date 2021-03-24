include Sufia::Export

# Convert a GenericFile including metadata, permissions and version metadata into a PORO
# so that the metadata can be exported in json format using to_json
#
class InvenioRdmRecordConverter < Sufia::Export::Converter
  include Galtersufia::GenericFile::InvenioResourceTypeMappings
  include Galtersufia::GenericFile::KnownOrganizations

  SUBJECT_SCHEMES = [:tag, :mesh, :lcsh]
  ENG = "eng"
  ENGLISH = "english"
  MEMOIZED_PERSON_OR_ORG_DATA_FILE = 'memoized_person_or_org_data.txt'
  ROLE_OTHER = 'other'
  DEFAULT_RIGHTS_SCHEME = "spdx"
  MEMOIZED_PERSON_OR_ORG_DATA_FILE = 'memoized_person_or_org_data.txt'
  FUNDING_DATA_FILE = 'app/models/concerns/galtersufia/generic_file/funding_data.txt'
  LICENSE_DATA_FILE = 'app/models/concerns/galtersufia/generic_file/license_data.txt'

  @@header_lookup ||= HeaderLookup.new
  @@funding_data ||= eval(File.read(FUNDING_DATA_FILE))
  @@person_or_org_data ||= eval(File.read(MEMOIZED_PERSON_OR_ORG_DATA_FILE))
  @@license_data ||= eval(File.read(LICENSE_DATA_FILE))

  # Create an instance of a InvenioRdmRecordConverter converter containing all the metadata for json export
  #
  # @param [GenericFile] generic_file file to be converted for export
  def initialize(generic_file=nil)
    return unless generic_file

    @record = record_for_export(generic_file)
    @file = filename_and_content_path(generic_file)
  end

  def to_json(options={})
    options[:except] ||= ["memoized_mesh", "memoized_lcsh"]
    super
  end

  private

  def filename_and_content_path(generic_file)
    {
      "filename": generic_file.filename,
      "content_path": generic_file_content_path(generic_file.content.checksum.value)
    }
  end

  def generic_file_content_path(checksum)
    # content paths are generated by taking the first 6 characters of its
    # checksum, and dividing it by 3
    "#{ENV["FEDORA_BINARY_PATH"]}/#{checksum[0..1]}/#{checksum[2..3]}/#{checksum[4..5]}/#{checksum}" unless !checksum
  end

  def record_for_export(generic_file)
    {
      "pids": invennio_pids(generic_file.doi.shift),
      "metadata": invenio_metadata(generic_file),
      "provenance": invenio_provenance(generic_file.proxy_depositor, generic_file.on_behalf_of)
    }
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
      "creators": gf.creator.map{ |creator| build_creator_contributor_json(creator) },
      "title": gf.title.first,
      "additional_titles": additional_titles(gf.title),
      "description": gf.description.first,
      "additional_descriptions": additional_descriptions(gf.description),
      "publisher": gf.publisher.shift,
      "publication_date": "#{gf.date_uploaded.year}-#{gf.date_uploaded.month}-#{gf.date_uploaded.day}",
      "subjects": SUBJECT_SCHEMES.map{ |subject_type| subjects_for_scheme(gf.send(subject_type), subject_type) }.flatten,
      "contributors": contributors(gf.contributor),
      "dates": gf.date_created.map{ |date| {"date": date, "type": "other", "description": "When the item was originally created."} },
      "languages": gf.language.any?{ |lang| lang.downcase == ENGLISH} ? ["eng"] : "",
      "identifiers": identifiers(gf.doi.shift),
      "sizes": Array.new.tap{ |size_json| size_json << "#{gf.page_count} pages" if !gf.page_count.blank? },
      "formats": gf.mime_type,
      "rights": rights(gf.rights),
      "locations": gf.based_near.present? ? gf.based_near.shift.split("', ").map{ |location| {place: location.gsub("'", "")} } : {},
      "funding": funding(gf.id)
    }
  end

  def resource_type(digitalhub_subtype)
    irdm_types = DH_IRDM_RESOURCE_TYPES[digitalhub_subtype]

    if irdm_types && irdm_types[1]
      {
        "type": irdm_types[0],
        "subtype": irdm_types[1]
      }
    elsif irdm_types # only Dataset has no subtype
      {
        "type": irdm_types[0]
      }
    else # for resource types with no mappings
      {
        "type": "other",
        "subtype": "other-other"
      }
    end
  end

  def build_creator_contributor_json(creator)
    if creator_data = @@person_or_org_data[creator]
      return creator_data
    # Organization
    elsif organization?(creator)
      json = @@person_or_org_data[creator] = {
        "person_or_org":
          Hash.new.tap do |hash|
            hash["name"] =  creator
            hash["type"] = "organisational"
          end
      }
    # User within DigitalHub
    elsif dh_user = User.find_by(formal_name: creator)
      dh_user_formal_name = dh_user.formal_name.split(',') # split name into components to be reused
      family_name = dh_user_formal_name.shift # remove first value from formal name
      given_name = dh_user_formal_name.join(' ') # the remaining strings becomes given name

      json = @@person_or_org_data[creator] = {
        "person_or_org":
          Hash.new.tap do |hash|
            hash["type"] = "personal"
            hash["given_name"] = given_name
            hash["family_name"] = family_name
            hash["identifiers"] = {"scheme": "orcid", "identifier": dh_user.orcid.split('/').pop} if dh_user.orcid.present?
          end
      }
    # Personal record without user in database
    elsif creator.include?(",")
      family_name, given_name = creator.split(',')
      json = @@person_or_org_data[creator] = {
        "person_or_org":
          Hash.new.tap do |hash|
            hash["type"] = "personal"
            hash["given_name"] = given_name.lstrip
            hash["family_name"] = family_name.lstrip
          end
      }
    # Unknown / Not Identified creator
    else
      json = @@person_or_org_data[creator] = {
        "person_or_org":
          Hash.new.tap do |hash|
            hash["name"] = creator
            hash["type"] = "organisational"
          end
      }
    end

    # this line only runs if there is an update to @@person_or_org_data
    File.write(MEMOIZED_PERSON_OR_ORG_DATA_FILE, @@person_or_org_data)
    # return the actual json
    json
  end # build_creator_contributor_json

  def additional_titles(titles)
    additional_titles_size = titles.size-1
    return nil if additional_titles_size < 0
    titles.last(additional_titles_size).map{ |title| {"title": title, "type": "alternative_title", "lang": ENG} }
  end

  def additional_descriptions(descriptions)
    additional_descriptions_size = descriptions.size-1
    return nil if additional_descriptions_size < 0
    descriptions.last(additional_descriptions_size).map{ |add_desc| {"description": add_desc, "type": "other", "lang": ENG} }
  end

  # return array of invenio formatted subjects
  def subjects_for_scheme(terms, scheme)
    if scheme != :tag
      terms.map do |term|
        pid = @@header_lookup.pid_lookup_by_scheme(term, scheme)

        if pid.present?
          {subject: term, identifier: pid, scheme: scheme}
        else
          {subject: "#{term}: DigitalHub field #{scheme}"}
        end
      end
    else
      terms.map{ |term| {subject: term} }
    end
  end

  def contributors(contributors)
    contributors.map do |contributor|
      contributor_json = build_creator_contributor_json(contributor)
      contributor_json[:person_or_org].merge!({"role": ROLE_OTHER})
      contributor_json
    end
  end

  def identifiers(doi)
    [{
      "identifier": doi,
      "scheme": "doi"
    }]
  end

  def rights(license_urls)
    license_urls.map do |license_url|
      license_data = @@license_data[license_url.to_sym]

      {
        "rights": license_data[:"name"],
        "scheme": DEFAULT_RIGHTS_SCHEME,
        "identifier": license_data[:"licenseId"],
        "url": license_url
      }
    end
  end

  def funding(file_id)
    @@funding_data[file_id] || {}
  end
end
