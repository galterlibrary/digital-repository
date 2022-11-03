include Sufia::Export

# Convert a GenericFile including metadata, permissions and version metadata into a PORO
# so that the metadata can be exported in json format using to_json
#
class InvenioRdmRecordConverter < Sufia::Export::Converter
  include Galtersufia::GenericFile::InvenioResourceTypeMappings
  include Galtersufia::GenericFile::KnownOrganizations

  SUBJECT_FIELDS = [:tag, :mesh, :lcsh, :subject_name, :subject_geographic]
  CIRCA_VALUES = ["ca.", "ca", "circa", "CA.", "CA", "CIRCA"]
  UNDATED = ["undated", "UNDATED"]
  ABBR_MONTHNAMES = Date::ABBR_MONTHNAMES.map{ |abbr_monthname| abbr_monthname.downcase if abbr_monthname.present? }
  MONTHNAMES = Date::MONTHNAMES.map{ |monthname| monthname.downcase if monthname.present? }
  SEASONS = ["spring", "summer", "fall", "winter"]
  LANGUAGES = {"english": "eng", "pali": "pli", "afrikaans": "afr", "polish": "pol", "italian": "ita", "french": "fra"}.with_indifferent_access
  ROLE_OTHER = 'role-other'
  OPEN_ACCESS = "open"
  INVENIO_PUBLIC = "public"
  INVENIO_RESTRICTED = "restricted"
  ALL_RIGHTS_RESERVED = 'All rights reserved'
  DOI_ORG = "doi.org/"
  MEMOIZED_PERSON_OR_ORG_DATA_FILE = 'memoized_person_or_org_data.txt'
  FUNDING_DATA_FILE = 'app/models/concerns/galtersufia/generic_file/funding_data.txt'
  LICENSE_DATA_FILE = 'app/models/concerns/galtersufia/generic_file/license_data.txt'
  DH_COLLECTIONS_TO_PRISM_COLLECTION_COMMUNITY_JSON = 'dh_collections_prism_collection_community.json'
  BLANK_FUNDER_SOURCE = {funder: {name: "", identifier: "", scheme: "ror"}, award: {title: "", number: "", identifier: "", scheme: ""}}
  INSTITUTIONAL_PNB_DEPOSITOR = "Institutional Pnb"
  PNB_DOI_PREFIX = "10.15844"

  @@header_lookup ||= HeaderLookup.new
  @@funding_data ||= eval(File.read(FUNDING_DATA_FILE))
  @@person_or_org_data ||= eval(File.read(MEMOIZED_PERSON_OR_ORG_DATA_FILE))
  @@license_data ||= eval(File.read(LICENSE_DATA_FILE))
  @@dh_to_prism_entity = JSON.parse(File.read(DH_COLLECTIONS_TO_PRISM_COLLECTION_COMMUNITY_JSON))

  # Create an instance of a InvenioRdmRecordConverter converter containing all the metadata for json export
  #
  # @param [GenericFile] generic_file file to be converted for export
  def initialize(generic_file=nil, collection_store={}, role_store={})
    @generic_file = generic_file
    @role_store = role_store
    # communites are necessary to check if the file should be exported
    @collection_store = collection_store
    # communities is an array consisting of collection paths which are arrays of hashes
    @dh_collections = list_collections

    @record = record_for_export
    @file = file_info
    @extras = extra_data
    @prism_community = dh_collection_to_prism_community_collection
  end

  def to_json(options={})
    return "{}" if @generic_file.unexportable?(@dh_collections)
    options[:except] ||= ["memoized_mesh", "memoized_lcsh", "generic_file", "collection_store", "role_store", "dh_collections"]
    super
  end

  private

  def file_info
    {
      "filename": @generic_file.filename,
      "content_path": generic_file_content_path(@generic_file.content.checksum.value),
      "original_checksum": @generic_file.original_checksum
    }
  end

  def generic_file_content_path(checksum)
    # content paths are generated by taking the first 6 characters of its
    # checksum, and dividing it by 3
    "#{ENV["FEDORA_BINARY_PATH"]}/#{checksum[0..1]}/#{checksum[2..3]}/#{checksum[4..5]}/#{checksum}" unless !checksum
  end

  def extra_data
    data = {}

    if !@generic_file.based_near.empty?
      data["presentation_location"] = @generic_file.based_near
    end
    data["permissions"] = file_permissions

    data
  end

  def owner_info(depositor)
    user = User.find_by(username: depositor)

    if user
      {user.username => user_email(user)}
    else
      {"unknown": "unknown"}
    end
  end

  def file_permissions
    permission_data = Hash.new

    permission_data["owner"] = owner_info(@generic_file.depositor)

    @generic_file.permissions.each do |permission|
      permission_data[permission.access] ||= Hash.new

      if @role_store[permission.agent_name]
        permission_data[permission.access].merge!(@role_store[permission.agent_name])
      elsif user = User.find_by(username: permission.agent_name)
        permission_data[permission.access].merge!({user.username => user_email(user)})
      else
        permission_data[permission.access].merge!({permission.agent_name => ""})
      end
    end

    permission_data
  end

  def list_collections
    collection_paths = []

    @generic_file.collection_ids.each do |collection_id|
      @collection_store[collection_id][:paths].each do |path|
        collection_paths << path
      end
    end

    collection_paths
  end

  def record_for_export
    {
      "pids": invenio_pids(@generic_file.doi.shift),
      "metadata": invenio_metadata,
      "files": {"enabled": true},
      "provenance": invenio_provenance(@generic_file.proxy_depositor, @generic_file.on_behalf_of),
      "access": invenio_access(@generic_file.visibility)
    }
  end

  def invenio_pids(doi)
    if doi.blank?
      {}
    else
      {
        "doi": {
          "identifier": doi.strip,
          "provider": "datacite",
          "client": "digitalhub"
        }
      }
    end
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

  def invenio_access(file_visibility)
    accessibility = file_visibility == OPEN_ACCESS ? INVENIO_PUBLIC : INVENIO_RESTRICTED

    {
      "record": accessibility,
      "files": accessibility
    }
  end

  def invenio_metadata
    begin
      {
        "resource_type": resource_type(@generic_file.resource_type.shift),
        "creators": @generic_file.creator.map{ |creator| build_creator_contributor_json(creator) },
        "title": @generic_file.title.first,
        "additional_titles": format_additional("title", "alternative-title", @generic_file.title.drop(1)),
        "description": @generic_file.description.join("\n\n").force_encoding("UTF-8"),
        "additional_descriptions":
          format_additional("description", "acknowledgements", @generic_file.acknowledgments) +
          format_additional("description", "abstract", @generic_file.abstract) +
          format_additional("description", "other", @generic_file.based_near, "presentation_location: ") +
          format_additional("description", "other", [@generic_file.page_number.to_s.force_encoding("UTF-8")], "number_in_sequence: ") +
          format_additional("description", "other", @generic_file.bibliographic_citation, "original_citation: "),
        "publisher": publisher,
        "publication_date": format_publication_date(@generic_file.date_created.shift.presence || @generic_file.date_uploaded.to_s.force_encoding("UTF-8")),
        "subjects": SUBJECT_FIELDS.map{ |subject_field| subjects_for_field(@generic_file.send(subject_field), subject_field) }.compact.flatten.uniq,
        "contributors": contributors(@generic_file.contributor),
        "dates": format_dates(@generic_file.date_created),
        "languages": @generic_file.language.map{ |lang| LANGUAGES[lang.downcase] ? {"id": LANGUAGES[lang.downcase]} : nil }.compact,
        "identifiers": original_identifiers(@generic_file.identifier) + ark_identifiers(@generic_file.ark),
        "related_identifiers": related_identifiers(@generic_file.related_url),
        "sizes": sizes,
        "formats": [@generic_file.mime_type],
        "version": version(@generic_file.content),
        "rights": rights(@generic_file.rights),
        "locations": {},
        "funding": funding(@generic_file.id)
      }

    rescue => e
      puts "[!!!ERROR!!!] Problem for GenericFile: #{@generic_file.id}"
      puts "Error - #{e}".force_encoding("UTF-8")
      puts "Continuing..."
    end
  end

  def resource_type(digitalhub_subtype)
    irdm_types = DH_IRDM_RESOURCE_TYPES[digitalhub_subtype]

    if irdm_types
      {
        "id": irdm_types[1]
      }
    else # for resource types with no mappings
      {
        "id": "other-other"
      }
    end
  end

  def build_creator_contributor_json(creator)
    creatibutor_json = @@person_or_org_data[creator]
    return creatibutor_json if creatibutor_json

    family_name, given_name = creator.split(',', 2)
    given_name = given_name.to_s.lstrip
    family_name = family_name.to_s.lstrip
    display_name = creator.split(", ").reverse.join(" ").strip

    if !(given_name =~ /\d/)
      given_name = given_name.gsub(',', "")
    end

    dh_user = User.find_by(formal_name: creator) || User.find_by(display_name: display_name)

    # Known organization
    if organization?(creator)
      creatibutor_json = {
        "person_or_org": {
          "name": creator,
          "type": "organizational"
        }
      }
    # Personal record with user in database OR is a person's formal name
    elsif dh_user.present? || creator.include?(",")
      creatibutor_json = {
        "person_or_org": {
          "given_name": given_name,
          "family_name": family_name,
          "type": "personal"
        }
      }

      if dh_user&.orcid.present?
        identifiers = [{"scheme": "orcid", "identifier": dh_user.orcid.split('/').pop}]
        creatibutor_json.with_indifferent_access[:person_or_org].merge!({"identifiers": identifiers})
      end
    # Personal record without user in database
    # Unknown / Not Identified creator
    else
      creatibutor_json = {
        "person_or_org": {
          "name": creator,
          "type": "organizational"
        }
      }
    end


    @@person_or_org_data[creator] = creatibutor_json
    # this line only runs if there is an update to @@person_or_org_data
    File.write(MEMOIZED_PERSON_OR_ORG_DATA_FILE, @@person_or_org_data)
    # return the actual json
    creatibutor_json
  end # build_creator_contributor_json

  def format_additional(content_type, invenio_type, values, prefix="")
    formatted_values = values.map do |value|
      if value.blank?
        next
      else
        {"#{content_type}":  prefix + value.to_s.force_encoding("UTF-8"), "type": {"id": invenio_type}}
      end
    end

    formatted_values.compact
  end

  # return array of invenio formatted subjects
  def subjects_for_field(terms, field)
    mapped_terms = terms.map do |term|
      term = term.strip

      if term.blank?
        nil
      elsif field == :tag
        {subject: term.force_encoding("UTF-8")}
      elsif pid = @@header_lookup.pid_lookup_by_field(term, field)
        {id: pid}
      else
        puts "------\nUnable to map subject\nFile Id: #{@generic_file.id} Term: #{term} Subject Field: #{field}\n------".force_encoding("UTF-8")
      end
    end

    mapped_terms.compact
  end


  def contributors(contributors)
    contributors.map do |contributor|
      contributor_json = build_creator_contributor_json(contributor)
      contributor_json.merge!({"role": {id: ROLE_OTHER}})
      contributor_json
    end
  end

  def ark_identifiers(arks)
    arks.map do |ark|
      {
        "identifier": ark,
        "scheme": "ark"
      }
    end
  end

  def rights(license_urls)
    license_urls.map do |license_url|
      license_data = @@license_data[license_url.to_sym]

      if license_url == ALL_RIGHTS_RESERVED
        {
          "id": license_data[:"licenseId"],
          "title": {"en": license_data[:"name"]}
        }
      elsif license_data.present?
        {
          "id": license_data[:"licenseId"],
          "link": license_url,
          "title": {"en": license_data[:"name"]}
        }
      end
    end
  end

  def version(content)
    return "" unless content.has_versions?
    version_number = content.versions.all.length

    "v#{version_number}.0.0"
  end

  def related_identifiers(related_url)
    identifiers = related_url.map do |url|
      next if url.blank?

      if doi_url?(url)
        doi = url.split(DOI_ORG).last

        {
          "identifier": doi.force_encoding("UTF-8"),
          "scheme": "doi",
          "relation_type": {"id": "isRelatedTo"}
        }
      else
        {
          "identifier": url.force_encoding("UTF-8"),
          "scheme": "url",
          "relation_type": {"id": "isRelatedTo"}
        }
      end
    end

    identifiers.compact
  end

  def doi_url?(url)
    url.include?(DOI_ORG)
  end

  def format_publication_date(publication_date)
    normalize_date(publication_date)
  end

  def format_dates(dates)
    dates.reject(&:blank?).map do |date|
      {
        "date": normalize_date(date),
        "type": {"id": "created"},
        "description": "When the item was originally created."
      }
    end
  end

  def normalize_date(date_string)
    split_date = date_string.split(/[-,\/ ]/).map(&:downcase)
    # date format starts with month first
    if (!split_date.blank? && split_date[0].length < 3)
      split_date = rearrange_year(split_date)
    end

    month_names = (split_date & MONTHNAMES)
    abbr_month_names = (split_date & ABBR_MONTHNAMES)

    # blank and unddated
    if date_string.blank? || (split_date & UNDATED).any? || (split_date & SEASONS).any?
      return ""
    # circa date
    elsif (split_date & CIRCA_VALUES).any?
      return date_string.gsub(Regexp.union(CIRCA_VALUES), "").strip
    # date range without month name or month abbreviations
    elsif (split_date.length != 3 && date_string.length == 9)
      return date_string.gsub(" ", "").gsub("-", "/")
    # date range with month name or month abbreviations
    elsif month_names.length > 1 || abbr_month_names.length > 1
      # two months, one year
      if split_date.length == 3
        start_month = MONTHNAMES.index(split_date[0]) || ABBR_MONTHNAMES.index(split_date[0])
        end_month = MONTHNAMES.index(split_date[1]) || ABBR_MONTHNAMES.index(split_date[1])
        year = split_date.last.to_i

        return "#{Date.new(year, start_month).strftime("%Y-%m")}/#{Date.new(year, end_month).strftime("%Y-%m")}"
      # two months, two years
      else
        start_month = MONTHNAMES.index(split_date[0]) || ABBR_MONTHNAMES.index(split_date[0])
        start_year = split_date[1].to_i
        end_month = MONTHNAMES.index(split_date[2]) || ABBR_MONTHNAMES.index(split_date[2])
        end_year = split_date[3].to_i

        return "#{Date.new(start_year, start_month).strftime("%Y-%m")}/#{Date.new(end_year, end_month).strftime("%Y-%m")}"
      end
    # date with month or month abbreviation in it
    elsif month_names.present? || abbr_month_names.present?
      year = split_date.last.to_i
      month = MONTHNAMES.index(split_date[0]) || ABBR_MONTHNAMES.index(split_date[0])
      day = split_date[1].to_i
      day = nil if day == year
    # regular date
    else
      split_date.map!(&:to_i)
      split_date_length = split_date.length

      if split_date_length == 3
        year = split_date[0]
        month = split_date[1]
        day = split_date[2]
      elsif split_date_length == 2
        year = split_date[0]
        month = split_date[1]
      else split_date_length == 1
        year = split_date[0]
      end
    end

    # build the date
    if day && month && year
      Date.new(year, month, day).strftime("%Y-%m-%d")
    elsif month && year
      Date.new(year, month).strftime("%Y-%m")
    elsif year
      Date.new(year).strftime("%Y")
    else
      ""
    end
  end

  def rearrange_year(date_array)
    if date_array[0].length == 4
      return date_array
    end

    last_i = date_array.length - 1
    (1..last_i).each do |i|
      if date_array[i].length == 4
        date_array.insert(0, date_array.delete_at(i))
        return date_array
      end
    end

    date_array
  end

  def funding(file_id)
    funding_sources = @@funding_data[file_id]

    if funding_sources.blank?
      return []
    end

    funding_sources.map! do |source|
      # if the source is empty except for funder scheme, return empty
      if source == BLANK_FUNDER_SOURCE
        nil
      # if the title is blank, replace it with the award number
      elsif source[:award][:title].blank?
        source[:award][:title] = source[:award][:number]
        source
      else
        source
      end
    end

    # remove nil values
    funding_sources.compact
  end

  def dh_collection_to_prism_community_collection
    mapping_entry =
      @@dh_to_prism_entity[@generic_file.id] ||
      find_mapping_entry_in_dh_collections ||
      {"community_id": "", "collection_id": ""}

    return format_prism_community_collection_string(mapping_entry.with_indifferent_access)
  end

  def find_mapping_entry_in_dh_collections
    @dh_collections.map do |collection_path|
      collection_path.each do |collection_path_entry|
        mapping_entry = @@dh_to_prism_entity[collection_path_entry[:id]]

        # there's a match, no need to keep searching
        if mapping_entry
          return mapping_entry
        # part of pediatric neurology brief collection in format pnb-volume#-issue#
        elsif collection_path_entry[:id]&.starts_with?("pnb-")
          volume_number, issue_number = collection_path_entry[:id].split(/[^\d]/).reject(&:blank?)

          if issue_number.present?
            collection_id = "Volume #{"%02d" % volume_number}, Issue #{"%02d" % issue_number}"
          else
            collection_id = "Volume #{"%02d" % volume_number}"
          end

          return {
            "community_id": "pediatric-neurology-briefs",
            "collection_id": collection_id
          }
        end
      end
    end

    nil
  end

  def format_prism_community_collection_string(mapping_entry)
    community_id = mapping_entry["community_id"]
    collection_id = mapping_entry["collection_id"]

    if community_id.present? && collection_id.present?
      "#{community_id}::#{collection_id}"
    else
      community_id
    end
  end

  def original_identifiers(identifiers)
    isbn_count = 0

    identifiers = identifiers.map do |identifier|
      if identifier.include?("PMID")
        id = identifier.gsub(/\(PMID\)/, "").strip
        scheme = "pmid"
      elsif identifier.include?("DOI")
        # it's significantly less difficult to just do two removals than find a catch all here
        id = identifier.gsub(/DOI/, "").gsub(/[():]/, "").strip
        scheme = "doi"
      elsif identifier.include?("ISBN")
        id = identifier.gsub(/\(ISBN.*\)/, "").strip
        scheme = "isbn"
        isbn_count += 1
      elsif identifier.include?("PNB")
        id = identifier
        scheme = "other"
      else
        next
      end

      {
        "identifier": id,
        "scheme": scheme
      }
    end

    # if there are multiple isbn find the isbn with length 10 and remove it
    if isbn_count > 1
      identifiers = normalize_isbn(identifiers)
    end

    identifiers.compact
  end

  def normalize_isbn(identifiers)
    identifiers.map do |id_obj|
      if id_obj.present? && id_obj[:scheme] == "isbn" && id_obj[:identifier].to_s.length == 10
        nil
      else
        id_obj
      end
    end
  end

  def publisher
    # When the record is a Pediatric Neurology Brief specifically want the publisher: Pediatric Neurology Briefs Publishers
    if pediatric_neurology_brief?
      "Pediatric Neurology Briefs Publishers"
    # By default just take the first publisher
    else
      @generic_file.publisher.shift
    end
  end

  def pediatric_neurology_brief?
    @generic_file.depositor == INSTITUTIONAL_PNB_DEPOSITOR || @generic_file.doi.shift&.include?(PNB_DOI_PREFIX)
  end

  def sizes
    if @generic_file.id == "3105875f-61e1-412c-9b1c-c8a33b37ff35"
      ["116 pages"]
    elsif  @generic_file.id == "9cd9e3df-458c-4a2c-9e42-1dcdc95e7adf"
      ["44 pages"]
    elsif !@generic_file.page_count.blank?
      ["#{@generic_file.page_count.shift} pages"]
    else
      []
    end
  end

  def user_email(user)
    user.email == "joshelder@northwestern.edu" ? "JoshElder@northwestern.edu" : user.email
  end
end
