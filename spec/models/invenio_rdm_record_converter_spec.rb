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
  let(:generic_file) {
    make_generic_file(
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
      date_created: ["1-1-2021"],
      mime_type: 'application/pdf',
      grants_and_funding: ["European Commission 00k4n6c32"],
      language: ["English"],
      page_count: [rand(1..1000).to_s],
      rights: ["http://creativecommons.org/licenses/by-nc-sa/3.0/us/"]
    )
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
            "type": "book",
            "subtype": "book-account_book"
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
          "publication_date": "2020-2-3",
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
          "dates": [{"date": "1-1-2021", "type": "other", "description": "When the item was originally created."}],
          "languages": ["eng"],
          "sizes": ["#{generic_file.page_count} pages"],
          "formats": "application/pdf",
          "rights": [{"rights": 'Creative Commons Attribution Non Commercial Share Alike 3.0 United States', "scheme": "spdx", "identifier": \
                      "CC-BY-NC-SA-3.0-US", "url": "http://creativecommons.org/licenses/by-nc-sa/3.0/us/"}],
          "locations": [{"place": "Boston, Massachusetts, United States"}, {"place": "East Peoria, Illinois, United States"}],
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
            }}]},
        "provenance": {
          "created_by": {
            "user": assistant.username
          },
          "on_behalf_of": {
            "user": user.username
          }
        },
      },
      "file": {
        "filename": generic_file.filename,
        "content_path": nil # there is no file/content attached with this factory made GewnericFile
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
          "type": "image",
          "subtype": "image-pictorial_work"
        }
      }.to_json

      it "returns type and subtype" do
        expect(invenio_rdm_record_converter.send(:resource_type, "Image")).to eq(image)
      end
    end

    context "with type only" do
      let(:dataset) {
        {
          "type": "dataset"
        }
      }.to_json

      it "returns type only" do
        expect(invenio_rdm_record_converter.send(:resource_type, "Dataset")).to eq(dataset)
      end
    end

    context "with no mapping" do
      let(:project) {
        {
          "type": "other",
          "subtype": "other-other"
        }
      }.to_json

      it "returns 'other' type" do
        expect(invenio_rdm_record_converter.send(:resource_type, "Project")).to eq(project)
      end
    end
  end

  let(:creative_commons_attribution_v3_url) { "http://creativecommons.org/licenses/by/3.0/us/" }
  let(:expected_creative_commons_attribution_v3_url) do
    {
      "rights": "Creative Commons Attribution 3.0 United States",
      "scheme": "spdx",
      "identifier": "CC-BY-3.0-US",
      "url": creative_commons_attribution_v3_url
    }
  end

  let(:creative_commons_zero_url) { "http://creativecommons.org/publicdomain/zero/1.0/" }
  let(:expected_mit) do
    {
      "rights": "Creative Commons Zero v1.0 Universal",
      "scheme": "spdx",
      "identifier": "CC0-1.0",
      "url": creative_commons_zero_url
    }
  end


  let(:mit_license_url) { "https://opensource.org/licenses/MIT" }
  let(:expected_mit) do
    {
      "rights": "MIT License",
      "scheme": "spdx",
      "identifier": "MIT",
      "url": mit_license_url
    }
  end

  describe "#rights" do
    it 'returns the expected license information' do
      expect(subject.send(:rights, [creative_commons_attribution_v3_url])).to eq(expected_creative_commons_attribution_v3_url)
      expect(subject.send(:rights, [creative_commons_zero_url])).to eq(expected_creative_commons_zero_url)
      expect(subject.send(:rights, [mit_license_url])).to eq(expected_mit)
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
end
