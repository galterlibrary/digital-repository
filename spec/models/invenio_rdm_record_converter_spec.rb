require 'rails_helper'

RSpec.describe InvenioRdmRecordConverter do
  let(:user) { FactoryGirl.create(:user, username: "usr1234", formal_name: "Tester, Mock", orcid: "https://orcid.org/1234-5678-9123-4567", \
                                    display_name: 'Mock Tester') }
  let(:contributor_user) { FactoryGirl.create(:user, username: "contributor_user", formal_name: "User, Contributor",  display_name: 'Contributor User') }
  let(:assistant) { FactoryGirl.create(:user, username: "ast9876") }
  let(:mesh_term) { "Vocabulary, Controlled" }
  let(:expected_mesh_pid) { "D018875" }
  let(:lcsh_term) { "Semantic Web" }
  let(:expected_lcsh_pid) { "sh2002000569" }
  let(:generic_file_doi) { "10.5438/55e5-t5c0" }
  let(:generic_file) {
    make_generic_file_with_content(
      user,
      id: "ns0646000",
      doi: ["doi:123/ABC"],
      resource_type: ["Account Books"],
      proxy_depositor: assistant.username,
      on_behalf_of: user.username,
      creator: [user.formal_name],
      contributor: [contributor_user.formal_name],
      title: ["Primary Title"],
      tag: ["keyword subject"],
      publisher: ["DigitalHub. Galter Health Sciences Library & Learning Center"],
      date_uploaded: Time.new(2020, 2, 3),
      mesh: [mesh_term],
      lcsh: [lcsh_term],
      based_near: ["'Boston, Massachusetts, United States', 'East Peoria, Illinois, United States'"],
      description: ["This is a generic file for specs only", "This is an additional description to help test"],
      date_created: ["2021-1-1"],
      mime_type: 'application/pdf',
      grants_and_funding: ["European Commission 00k4n6c32"],
      language: ["English"],
      page_count: [rand(1..1000).to_s],
      rights: ["http://creativecommons.org/licenses/by-nc-sa/3.0/us/"],
      visibility: InvenioRdmRecordConverter::OPEN_ACCESS,
      related_url: ["https://doi.org/10.5438/55e5-t5c0"]
    )
  }
  let(:generic_file_checksum) { generic_file.content.checksum.value }
  let(:generic_file_content_path) {
    "#{ENV["FEDORA_BINARY_PATH"]}/#{generic_file_checksum[0..1]}/"\
    "#{generic_file_checksum[2..3]}/#{generic_file_checksum[4..5]}/#{generic_file_checksum}"
  }
  let(:json) do
    {
      "record": {
        "pids": {
          "doi": {
            "identifier": "#{generic_file.doi.shift}",
            "provider":"datacite",
            "client":"digitalhub"
          }
        },
        "metadata": {
          "resource_type": {
            "id": "book-account_book"
          },
          "creators": [{
            "person_or_org": {
              "type": "personal",
              "given_name": "#{user.formal_name.split(',').last}",
              "family_name": "#{user.formal_name.split(',').first}",
              "identifiers": {
                "scheme": "orcid",
                "identifier": "#{user.orcid.split('/').last}"
              }
            }
          }],
          "title": "#{generic_file.title.first}",
          "additional_titles": [
            {
              "title": "Secondary Title",
              "type": "alternative_title",
              "lang": InvenioRdmRecordConverter::ENG
            },
            {
              "title": "Tertiary Title",
              "type": "alternative_title",
              "lang": InvenioRdmRecordConverter::ENG
            }
          ],
          "description": generic_file.description.shift,
          "additional_descriptions": [{"description": generic_file.description.last, "type": "other", "lang": InvenioRdmRecordConverter::ENG}],
          "publisher": "DigitalHub. Galter Health Sciences Library & Learning Center",
          "publication_date": "2021-01-01",
          "subjects": [
            {
              "subject": "keyword subject",
            },
            {
              "subject": mesh_term,
              "identifier": expected_mesh_pid,
              "scheme": "mesh"
            },
            {
              "subject": lcsh_term,
              "identifier": expected_lcsh_pid,
              "scheme": "lcsh"
            }
          ],
          "contributors": [{
            "person_or_org": {
              "type": "personal",
              "given_name": "#{contributor_user.formal_name.split(',').last}",
              "family_name": "#{contributor_user.formal_name.split(',').first}",
              "role": InvenioRdmRecordConverter::ROLE_OTHER
            }
          }],
          "dates": [{"date": "2021-1-1", "type": "other", "description": "When the item was originally created."}],
          "languages": [{"id": "eng"}],
          "related_identifiers": [{
              "identifier": generic_file_doi,
              "scheme": "doi",
              "relation_type": {"id": "isRelatedTo"}
            }],
          "sizes": ["#{generic_file.page_count} pages"],
          "formats": "application/pdf",
          "version": "v1.0.0",
          "rights": [{
            "id": "CC-BY-NC-SA-3.0-US",
            "link": "http://creativecommons.org/licenses/by-nc-sa/3.0/us/",
            "title": 'Creative Commons Attribution Non Commercial Share Alike 3.0 United States'}],
          "locations": {
            "features": [{"place": "Boston, Massachusetts, United States"},
                         {"place": "East Peoria, Illinois, United States"}],
          },
          "funding": [{
            "funder": {
              "name": "National Library of Medicine (NLM)",
              "identifier": "0060t0j89",
              "scheme": "ror"
            },
            "award": {
              "title": "",
              "number": "F37 LM009568 ",
              "identifier": "",
              "scheme": ""
            }
          }]
        },
        "files": {
          "enabled": true
        },
        "provenance": {
          "created_by": {
            "user": assistant.username
          },
          "on_behalf_of": {
            "user": user.username
          }
        },
        "access": {
          "record": InvenioRdmRecordConverter::INVENIO_PUBLIC,
          "files": InvenioRdmRecordConverter::INVENIO_PUBLIC
        }
      },
      "file": {
        "filename": generic_file.filename,
        "content_path": generic_file_content_path
      }
    }.to_json
  end
  let(:invenio_rdm_record_converter) { described_class.new(generic_file) }

  before do
    ProxyDepositRights.create(grantor_id: assistant.id, grantee_id: user.id)
    # ensure order of titles is consistent by updating generic file with additional titles after creation
    generic_file.title << ["Secondary Title", "Tertiary Title"]
  end

  describe "#to_json" do
    subject { invenio_rdm_record_converter.to_json }

    it do
      is_expected.to eq json
    end
  end

  let(:converter) { InvenioRdmRecordConverter.new }
  let(:checksum) { "abcd1234" }
  let(:non_user_properly_formatted) { "Laster, Firston" }
  let(:personal_creator_without_user_json) {
    {
      "person_or_org": {
        "type": "personal",
        "given_name": "Firston",
        "family_name": "Laster",
      }
    }.with_indifferent_access
  }

  let(:non_user_improperly_formatted) { "Firston Laster" }
  let(:organisational_creator_without_user_json) {
    {
      "person_or_org": {
        "name": "Firston Laster",
        "type": "organisational"
      }
    }.with_indifferent_access
  }

  let(:unidentified_creator_name) { "Creator not identified." }
  let(:personal_creator_unidentified_json) {
      {
        "person_or_org": {
          "name": unidentified_creator_name,
          "type": "organisational"
        }
      }.with_indifferent_access
    }

  let(:unknown_creator_name) { "Unknown" }
  let(:personal_creator_unknown_json) {
    {
      "person_or_org": {
        "name": unknown_creator_name,
        "type": "organisational"
      }
    }.with_indifferent_access
  }

  let(:organization_name) { "Galter Health Sciences Library" }
  let(:organizational_creator_json) {
    {
      "person_or_org": {
        "name": organization_name,
        "type": "organisational"
      }
    }.with_indifferent_access
  }

  describe "#build_creator_contributor_json" do
    context 'personal record without user in digital hub, with proper name formatting' do
      it 'assigns' do
        expect(converter.send(:build_creator_contributor_json, non_user_properly_formatted).with_indifferent_access).to eq(personal_creator_without_user_json)
      end
    end

    context 'personal record without user in digital hub, with improper name formatting' do
      it 'assigns' do
        expect(converter.send(:build_creator_contributor_json, non_user_improperly_formatted).with_indifferent_access).to eq(organisational_creator_without_user_json)
      end
    end

    context 'personal record with unknown creator' do
      it 'assigns' do
        expect(converter.send(:build_creator_contributor_json, unknown_creator_name).with_indifferent_access).to eq(personal_creator_unknown_json)
      end
    end

    context 'personal record with unidentified user' do
      it 'assigns' do
        expect(converter.send(:build_creator_contributor_json, unidentified_creator_name).with_indifferent_access).to eq(personal_creator_unidentified_json)
      end
    end

    context 'organizational record' do
      it 'assigns' do
        expect(converter.send(:build_creator_contributor_json, organization_name).with_indifferent_access).to eq(organizational_creator_json)
      end
    end
  end

  describe "#generic_file_content_path" do
    it "returns the content's path" do
      expect(converter.send(:generic_file_content_path, checksum)).to eq("#{ENV['FEDORA_BINARY_PATH']}/ab/cd/12/abcd1234")
    end
  end

  describe "#funding" do
    context "file has no funding data" do
      let(:no_funding_file_id) { "this-is-not-a-file-id" }

      it "returns empty hash" do
        expect(invenio_rdm_record_converter.send(:funding, no_funding_file_id)).to eq({})
      end
    end

    context "file has multiple funding sources" do
      let(:multiple_funding_file_id) { "9z902z89q" }

      it "returns all funding sources" do
        expect(invenio_rdm_record_converter.send(:funding, multiple_funding_file_id).length).to eq(2)
      end
    end
  end

  describe "#resource_type" do
    context "with type and subtype" do
      let(:image) {
        {
          "id": "image-pictorial_work"
        }
      }.to_json

      it "returns type and subtype" do
        expect(invenio_rdm_record_converter.send(:resource_type, "Image")).to eq(image)
      end
    end

    let(:dataset) {
      {
        "id": "dataset"
      }
    }.to_json

    context "with type only" do
      it "returns type only" do
        expect(invenio_rdm_record_converter.send(:resource_type, "Dataset")).to eq(dataset)
      end
    end

    context "with no mapping" do
      let(:other) {
        {
          "id": "other-other"
        }
      }.to_json

      it "returns 'other' type" do
        expect(invenio_rdm_record_converter.send(:resource_type, "Project")).to eq(other)
      end
    end
  end

  let(:creative_commons_attribution_v3_url) { "http://creativecommons.org/licenses/by/3.0/us/" }
  let(:expected_creative_commons_attribution_v3) do
    [{
      "id": "CC-BY-3.0-US",
      "link": creative_commons_attribution_v3_url,
      "title": "Creative Commons Attribution 3.0 United States"
    }]
  end

  let(:creative_commons_zero_url) { "http://creativecommons.org/publicdomain/zero/1.0/" }
  let(:expected_creative_commons_zero) do
    [{
      "id": "CC0-1.0",
      "link": creative_commons_zero_url,
      "title": "Creative Commons Zero v1.0 Universal"
    }]
  end

  let(:mit_license_url) { "https://opensource.org/licenses/MIT" }
  let(:expected_mit) do
    [{
      "id": "MIT",
      "link": mit_license_url,
      "title": "MIT License"
    }]
  end

  let(:all_rights_reserved) { 'All rights reserved' }
  let(:expected_all_rights_reserved) do
    [{
      "id": "GALTER-ARR-1.0",
      "title": all_rights_reserved
    }]
  end

  let(:multiple_rights) { ["https://opensource.org/licenses/MIT", "http://creativecommons.org/publicdomain/zero/1.0/"] }
  let(:expected_multiple_rights) do
    [{
      "rights": "MIT License",
      "scheme": "spdx",
      "identifier": "MIT",
      "url": mit_license_url
    },
    {
      "rights": "Creative Commons Zero v1.0 Universal",
      "scheme": "spdx",
      "identifier": "CC0-1.0",
      "url": creative_commons_zero_url
    }]
  end

  describe "#rights" do
    it 'returns the expected license information' do
      expect(subject.send(:rights, [creative_commons_attribution_v3_url])).to eq(expected_creative_commons_attribution_v3)
      expect(subject.send(:rights, [creative_commons_zero_url])).to eq(expected_creative_commons_zero)
      expect(subject.send(:rights, [mit_license_url])).to eq(expected_mit)
      expect(subject.send(:rights, [all_rights_reserved])).to eq(expected_all_rights_reserved)
      expect(subject.send(:rights, multiple_rights)).to eq(expected_multiple_rights)
    end
  end

  let(:doi) { "10.18131/g3-hgs7-ag90" }
  let(:doi_org_url) { "https://doi.org/#{doi}" }
  let(:dx_doi_org_url) { "https://dx.doi.org/10.6084/m9.figshare.2002149" }
  let(:non_doi_url) { "www.google.com" }

  describe "#doi_url?" do
    it 'returns true for urls that include doi.org' do
      expect(subject.send(:doi_url?, doi_org_url)).to eq(true)
      expect(subject.send(:doi_url?, dx_doi_org_url)).to eq(true)
      expect(subject.send(:doi_url?, non_doi_url)).to eq(false)
    end
  end

  let(:expected_doi_related_identifiers_json) do
    {
      "identifier": doi,
      "scheme": "doi",
      "relation_type": {"id": "isRelatedTo"}
    }
  end
  let(:expected_related_identifiers_json) do
    {
      "identifier": non_doi_url,
      "scheme": "url",
      "relation_type": {"id": "isRelatedTo"}
    }
  end

  describe "#related_identifiers" do
    context 'there is no related_url' do
      it 'returns an empty array' do
        expect(subject.send(:related_identifiers, [])).to eq([])
      end
    end

    context 'with related_url' do
      it 'returns formatted json' do
        expect(subject.send(:related_identifiers, [doi_org_url])).to eq([expected_doi_related_identifiers_json])
        expect(subject.send(:related_identifiers, [non_doi_url])).to eq([expected_related_identifiers_json])
      end
    end
  end

  let(:blank_text_field) { [""] }

  context 'when text field is empty' do
    describe "#additional_titles" do
      it 'returns empty array' do
        expect(subject.send(:additional_titles, blank_text_field)).to eq([])
      end
    end

    describe "#additional_descriptions" do
      it 'returns empty array' do
        expect(subject.send(:additional_descriptions, blank_text_field)).to eq([])
      end
    end
  end

  describe "#normalize_date" do
    context "formatted date" do
      let(:expected_formatted_date_1){ "1907-09-06" }
      let(:expected_formatted_date_2){ "1920-12-01" }
      let(:date_without_zero_padding_1){ "1920-12-1" }
      let(:date_without_zero_padding_2){ "1907-9-6" }
      let(:date_with_dashes){ expected_formatted_date_1 }
      let(:date_with_slashes){ "1907/09/06" }

      it "normalizes date" do
        expect(invenio_rdm_record_converter.send(:normalize_date, date_without_zero_padding_1)).to eq(expected_formatted_date_2)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_without_zero_padding_2)).to eq(expected_formatted_date_1)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_dashes)).to eq(expected_formatted_date_1)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_slashes)).to eq(expected_formatted_date_1)
      end
    end

    context "date with month and year only" do
      let(:date_with_dashes_month_only){ "1903-06" }
      let(:date_with_slashes_month_only){ "1903/06" }

      it "normalizes date with year and month available" do
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_dashes_month_only)).to eq(date_with_dashes_month_only)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_slashes_month_only)).to eq(date_with_dashes_month_only)
      end
    end

    context "date with year only" do
      let(:date_with_year_only){ "1899" }
      let(:expected_date_with_year_only){ "1899" }

      it "normalizes date with only year available" do
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_year_only)).to eq(expected_date_with_year_only)
      end
    end

    context "normalizes date with ca or similar text" do
      let(:circa_date){ "ca. 1900" }
      let(:formatted_circa_date){ "1900" }

      it "normalizes date" do
        expect(invenio_rdm_record_converter.send(:normalize_date, circa_date)).to eq(formatted_circa_date)
      end
    end

    context "date with month name or abbreviation" do
      let(:january_month_name_date){ "January 12, 2020" }
      let(:march_month_name_date){ "MARCH 2020" }
      let(:november_month_name_date){ "november 15, 1900" }

      let(:january_abr_month_name_date){ "Jan 12, 2020" }
      let(:march_abr_month_name_date){ "MAR 2020" }
      let(:november_abr_month_name_date){ "nov 15, 1900" }

      let(:normalized_january_month_name_date){ "2020-01-12" }
      let(:normalized_march_month_name_date){"2020-03"}
      let(:normalized_november_month_name_date){ "1900-11-15" }

      let(:range_uppercase){ "JANUARY-JUNE 2002" }
      let(:range_titlecase){ "May 2014-July 2014" }
      let(:normalized_range_uppercase){ "2002-01/2002-06" }
      let(:normalized_range_titlecase){ "2014-05/2014-07" }

      it "normalizes abbreviation" do
        expect(invenio_rdm_record_converter.send(:normalize_date, january_abr_month_name_date)).to eq(normalized_january_month_name_date)
        expect(invenio_rdm_record_converter.send(:normalize_date, march_abr_month_name_date)).to eq(normalized_march_month_name_date)
        expect(invenio_rdm_record_converter.send(:normalize_date, november_abr_month_name_date)).to eq(normalized_november_month_name_date)
      end

      it "normalizes full name" do
        expect(invenio_rdm_record_converter.send(:normalize_date, january_month_name_date)).to eq(normalized_january_month_name_date)
        expect(invenio_rdm_record_converter.send(:normalize_date, march_month_name_date)).to eq(normalized_march_month_name_date)
        expect(invenio_rdm_record_converter.send(:normalize_date, november_month_name_date)).to eq(normalized_november_month_name_date)
      end

      it "normalizes date with month range" do
        expect(invenio_rdm_record_converter.send(:normalize_date, range_uppercase)).to eq(normalized_range_uppercase)
        expect(invenio_rdm_record_converter.send(:normalize_date, range_titlecase)).to eq(normalized_range_titlecase)
      end
    end

    context "date ranges" do
      let(:slash_range){ "1895/1905" }
      let(:dash_range){ "1895-1905" }

      it 'normalizes date with year range' do
        expect(invenio_rdm_record_converter.send(:normalize_date, slash_range)).to eq(slash_range)
        expect(invenio_rdm_record_converter.send(:normalize_date, dash_range)).to eq(slash_range)
      end
    end

    context "blank or undated" do
      let(:blank_string){ "" }
      let(:undated_lower_case){ "undated" }
      let(:undated_upper_case){ "UNDATED" }

      it "normalizes undated or blank dates" do
        expect(invenio_rdm_record_converter.send(:normalize_date, blank_string)).to eq(blank_string)
        expect(invenio_rdm_record_converter.send(:normalize_date, undated_lower_case)).to eq(blank_string)
        expect(invenio_rdm_record_converter.send(:normalize_date, undated_upper_case)).to eq(blank_string)
      end
    end
  end
end
