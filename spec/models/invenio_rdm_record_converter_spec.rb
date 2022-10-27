require 'rails_helper'

RSpec.describe InvenioRdmRecordConverter do
  let(:user) { FactoryGirl.create(:user, username: "usr1234", formal_name: "Tester, Mock", orcid: "https://orcid.org/1234-5678-9123-4567", \
                                    display_name: 'Mock Tester') }
  let(:contributor_user) { FactoryGirl.create(:user, username: "contributor_user", formal_name: "User, Contributor",  display_name: 'Contributor User') }
  let(:creator_user) { FactoryGirl.create(:user, username: "creator_user", formal_name: "User, Creator James",  display_name: 'Creator User') }
  let(:assistant) { FactoryGirl.create(:user, username: "ast9876") }
  let(:lcnaf_term) { "Birkan, Kaarin" }
  let(:expected_lcnaf_term) {}
  let(:mesh_term) { "Vocabulary, Controlled" }
  let(:expected_mesh_id) { "https://id.nlm.nih.gov/mesh/D018875" }
  let(:expected_lcnaf_id) { "http://id.loc.gov/authorities/names/n90699999" }
  let(:lcsh_term) { "Semantic Web" }
  let(:duplicate_subject_term) { "Tampa Joe" }
  let(:expected_lcsh_id) { "http://id.loc.gov/authorities/subjects/sh2002000569" }
  let(:generic_file_doi) { "10.5438/55e5-t5c0" }
  let(:generic_file) {
    make_generic_file_with_content(
      user,
      id: "ns0646000",
      doi: ["doi:123/ABC"],
      ark: ["10.6666/ARK"],
      resource_type: ["Account Books"],
      proxy_depositor: assistant.username,
      on_behalf_of: user.username,
      creator: [user.formal_name, creator_user.display_name],
      contributor: [contributor_user.formal_name],
      title: ["Primary Title"],
      subject_name: [lcnaf_term, duplicate_subject_term],
      tag: [lcnaf_term, duplicate_subject_term],
      publisher: ["DigitalHub. Galter Health Sciences Library & Learning Center"],
      date_uploaded: Time.new(2020, 2, 3),
      mesh: [mesh_term],
      lcsh: [lcsh_term],
      subject_geographic: ["Boston (Mass.)", "Chicago (Ill.)"],
      based_near: ['East Peoria, Illinois, United States', 'Boston, Massachusetts, United States'],
      description: ["This is a generic file for specs only", "This is an additional description to help test"],
      date_created: ["2021-1-1"],
      mime_type: 'application/pdf',
      grants_and_funding: ["European Commission 00k4n6c32"],
      language: ["Pali", "English", "Fake Language"],
      page_count: [rand(1..1000).to_s],
      rights: ["http://creativecommons.org/licenses/by-nc-sa/3.0/us/"],
      visibility: InvenioRdmRecordConverter::OPEN_ACCESS,
      related_url: ["https://doi.org/10.5438/55e5-t5c0"],
      acknowledgments: ["this is an acknowledgement"],
      abstract: ["this is an abstract"],
      identifier: [
       "(DOI):46589",
       "(PMID) 11549777",
       "cruisemicrobe",
       "615.778-2",
       "600-15",
       "m19090127",
       "HSL.2016.15.0007",
       "(ISBN 10) 3956501241",
       "(ISBN) 9783956501241",
       "PNB-14-96-a",
       "PNB-15-10"
     ],
     page_number: "29a",
     bibliographic_citation: ["This is a citation", "This is another citation"]
    )
  }
  let(:generic_file_checksum) { generic_file.content.checksum.value }
  let(:generic_file_content_path) {
    "#{ENV["FEDORA_BINARY_PATH"]}/#{generic_file_checksum[0..1]}/"\
    "#{generic_file_checksum[2..3]}/#{generic_file_checksum[4..5]}/#{generic_file_checksum}"
  }
  let(:collection_store) { CollectionStore.new }
  let(:role_store) { RoleStore.new }
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
              "given_name": "#{creator_user.formal_name.split(',').last.strip}",
              "family_name": "#{creator_user.formal_name.split(',').first.strip}"
            }
          },
          {
            "person_or_org": {
              "type": "personal",
              "given_name": "#{user.formal_name.split(',').last}",
              "family_name": "#{user.formal_name.split(',').first}",
              "identifiers": [{
                "scheme": "orcid",
                "identifier": "#{user.orcid.split('/').last}"
              }]
            }
          }],
          "title": "#{generic_file.title.first}",
          "additional_titles": [
            {
              "title": "Secondary Title",
              "type": {"id": "alternative-title"}
            },
            {
              "title": "Tertiary Title",
              "type": {"id": "alternative-title"}
            }
          ],
          "description": "This is a generic file for specs only\n\nThis is an additional description to help test",
          "additional_descriptions": [
            {
              "description": generic_file.acknowledgments.first,
              "type": {
                "id": "acknowledgements"
              }
            },
            {
              "description": generic_file.abstract.first,
              "type": {
                "id": "abstract"
              }
            },
            {
              "description": "presentation_location: Boston, Massachusetts, United States",
              "type": {
                "id": "other"
              }
            },
            {
              "description": "presentation_location: East Peoria, Illinois, United States",
               "type": {
                 "id": "other"
               }
            },
            {
              "description": "number_in_sequence: 29a",
              "type": {
                "id": "other"
              }
            },
            {
              "description": "original_citation: This is another citation",
              "type": {
                "id": "other"
              }
            },
            {
              "description": "original_citation: This is a citation",
              "type": {
                "id": "other"
              }
            }
          ],
          "publisher": "DigitalHub. Galter Health Sciences Library & Learning Center",
          "publication_date": "2021-01-01",
          "subjects": [
            {
              "subject": lcnaf_term
            },
            {
              "subject": duplicate_subject_term
            },
            {
              "id": expected_mesh_id
            },
            {
              "id": expected_lcsh_id
            },
            {
              "id": expected_lcnaf_id
            },
            {
              "id": "http://id.loc.gov/authorities/names/n94099999" # tampa joe
            },
            {
              "id": "http://id.loc.gov/authorities/names/n78086438" # chicago
            },
            {
              "id": "http://id.loc.gov/authorities/names/n79045553" # boston
            }
          ],
          "contributors": [{
            "person_or_org": {
              "type": "personal",
              "given_name": "#{contributor_user.formal_name.split(',').last}",
              "family_name": "#{contributor_user.formal_name.split(',').first}",
            },
            "role": {"id": InvenioRdmRecordConverter::ROLE_OTHER}
          }],
          "dates": [{"date": "2021-01-01", "type": {"id":"created"}, "description": "When the item was originally created."}],
          "languages": [{"id": "pli"}, {"id": "eng"}],
          "identifiers": [{
              "identifier": "11549777",
              "scheme": "pmid"
            },
            {
              "identifier": "46589",
              "scheme": "doi"
            },
            {
              "identifier": "PNB-14-96-a",
              "scheme": "other"
            },
            {
              "identifier": "PNB-15-10",
              "scheme": "other"
            },
            {
              "identifier": "9783956501241",
              "scheme": "isbn"
            },
            {
              "identifier": "10.6666/ARK",
              "scheme": "ark"
            }
          ],
          "related_identifiers": [{
              "identifier": generic_file_doi,
              "scheme": "doi",
              "relation_type": {"id": "isRelatedTo"}
            }],
          "sizes": ["#{generic_file.page_count.shift} pages"],
          "formats": ["application/pdf"],
          "version": "v1.0.0",
          "rights": [{
            "id": "cc-by-nc-sa-3.0-us",
            "link": "http://creativecommons.org/licenses/by-nc-sa/3.0/us/",
            "title": {"en": 'Creative Commons Attribution Non Commercial Share Alike 3.0 United States'}}],
          "locations": {},
          "funding": [{
            "funder": {
              "name": "National Library of Medicine (NLM)",
              "identifier": "0060t0j89",
              "scheme": "ror"
            },
            "award": {
              "title": "F37 LM009568 ",
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
        "content_path": generic_file_content_path,
        "original_checksum": generic_file.original_checksum
      },
      "extras": {
        "presentation_location": generic_file.based_near,
        "permissions": {
          "owner": {
            user.username => user.email
          },
          "read": {
            "public": ""
          },
          "edit": {
            user.username => user.email,
          }
        }.with_indifferent_access
      },
      "prism_community": ""
    }.to_json
  end
  let(:invenio_rdm_record_converter) {
    described_class.new(generic_file, collection_store.data, role_store.data)
  }
  let(:unexportable_generic_file_upper) { make_generic_file_with_content(user, title: ["Test file - Combined"]) }
  let(:unexportable_generic_file_lower) { make_generic_file_with_content(user, title: ["Test file - combined"]) }

  before do
    ProxyDepositRights.create(grantor_id: assistant.id, grantee_id: user.id)
    # ensure order of titles is consistent by updating generic file with additional titles after creation
    generic_file.title << ["Secondary Title", "Tertiary Title"]
  end

  describe "#to_json" do
    context "record is exportable" do
      subject { invenio_rdm_record_converter.to_json }

      it "returns formatted json string" do
        is_expected.to eq json
      end
    end

    context "record is unexportable" do
      it "returns blank json string" do
        allow(generic_file).to receive(:unexportable?).and_return(true)
        expect(invenio_rdm_record_converter.to_json).to eq "{}"
        expect(unexportable_generic_file_upper.unexportable?([])).to eq true
        expect(unexportable_generic_file_lower.unexportable?([])).to eq true
      end
    end
  end

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
  let(:organizational_creator_without_user_json) {
    {
      "person_or_org": {
        "name": "Firston Laster",
        "type": "organizational"
      }
    }.with_indifferent_access
  }

  let(:unidentified_creator_name) { "Creator not identified." }
  let(:personal_creator_unidentified_json) {
      {
        "person_or_org": {
          "name": unidentified_creator_name,
          "type": "organizational"
        }
      }.with_indifferent_access
    }
  let(:non_user_with_suffix) { "Miller, Alfred Frederick, Jr." }
  let(:creator_with_suffix_json) {
    {
      "person_or_org": {
        "given_name": "Alfred Frederick Jr.",
        "family_name": "Miller",
        "type": "personal"
      }
    }.with_indifferent_access
  }

  let(:non_user_with_middle_initial) { "Mckay, Frederick, S." }
  let(:creator_with_middle_initial_json) {
    {
      "person_or_org": {
        "given_name": "Frederick S.",
        "family_name": "Mckay",
        "type": "personal"
      }
    }.with_indifferent_access
  }

  let(:non_user_with_date) { "Mason, Michael L., 1895-1963" }
  let(:creator_with_date_json) {
    {
      "person_or_org": {
        "given_name": "Michael L., 1895-1963",
        "family_name": "Mason",
        "type": "personal"
      }
    }.with_indifferent_access
  }

  let(:unknown_creator_name) { "Unknown" }
  let(:personal_creator_unknown_json) {
    {
      "person_or_org": {
        "name": unknown_creator_name,
        "type": "organizational"
      }
    }.with_indifferent_access
  }

  let(:organization_name) { "Northwestern University (Evanston, Ill.). Medical Alumni Association" }
  let(:organizational_creator_json) {
    {
      "person_or_org": {
        "name": organization_name,
        "type": "organizational"
      }
    }.with_indifferent_access
  }

  describe "#build_creator_contributor_json" do
    context 'personal record without user in digitalhub with proper name formatting' do
      it 'assigns' do
        expect(invenio_rdm_record_converter.send(:build_creator_contributor_json, non_user_properly_formatted).with_indifferent_access).to eq(personal_creator_without_user_json)
      end
    end

    context 'personal record without user in digitalhub with improper name formatting' do
      it 'assigns' do
        expect(invenio_rdm_record_converter.send(:build_creator_contributor_json, non_user_improperly_formatted).with_indifferent_access).to eq(organizational_creator_without_user_json)
      end
    end

    context 'personal record without user in digitalhub with middle initial in name' do
      it 'assigns' do
        expect(invenio_rdm_record_converter.send(:build_creator_contributor_json, non_user_with_middle_initial).with_indifferent_access).to eq(creator_with_middle_initial_json)
      end
    end

    context 'personal record without user in digitalhub with generational suffix in name' do
      it 'assigns' do
        expect(invenio_rdm_record_converter.send(:build_creator_contributor_json, non_user_with_suffix).with_indifferent_access).to eq(creator_with_suffix_json)
      end
    end

    context 'personal record without user in digitalhub with date in name' do
      it 'assigns' do
        expect(invenio_rdm_record_converter.send(:build_creator_contributor_json, non_user_with_date).with_indifferent_access).to eq(creator_with_date_json)
      end
    end

    context 'personal record with unknown creator' do
      it 'assigns' do
        expect(invenio_rdm_record_converter.send(:build_creator_contributor_json, unknown_creator_name).with_indifferent_access).to eq(personal_creator_unknown_json)
      end
    end

    context 'personal record with unidentified user' do
      it 'assigns' do
        expect(invenio_rdm_record_converter.send(:build_creator_contributor_json, unidentified_creator_name).with_indifferent_access).to eq(personal_creator_unidentified_json)
      end
    end

    context 'organizational record' do
      it 'assigns' do
        expect(invenio_rdm_record_converter.send(:build_creator_contributor_json, organization_name).with_indifferent_access).to eq(organizational_creator_json)
      end
    end
  end

  describe "#generic_file_content_path" do
    it "returns the content's path" do
      expect(invenio_rdm_record_converter.send(:generic_file_content_path, checksum)).to eq("#{ENV['FEDORA_BINARY_PATH']}/ab/cd/12/abcd1234")
    end
  end

  let(:expected_extra_data) {
    {
      "presentation_location": ["Boston, Massachusetts, United States", "East Peoria, Illinois, United States"],
      "permissions": {
        "owner": {
          user.username => user.email
        },
        "read": {
          "public": ""
        },
        "edit": {
          user.username => user.email,
        }
      }.with_indifferent_access
    }.with_indifferent_access
  }

  describe "#extra_data" do
    it "adds data" do
      expect(invenio_rdm_record_converter.send(:extra_data).with_indifferent_access).to eq(expected_extra_data)
    end
  end

  describe "#file_permissions" do
    let(:role) { Role.create(name: 'export_editor') }
    let(:exporter) { FactoryGirl.create(:user, username: "exp987") }
    before do
      exporter.add_role(role.name)
      generic_file.permissions.create!(
        name: role.name, type: 'group', access: 'edit',
        access_to: generic_file.id)
    end

    context "with role" do
      before do
        role_store.build_role_store_data
      end

      let(:expected_permissions) {
        {
          "owner": {
            user.username => user.email
          },
          "read": {
            "public": ""
          },
          "edit": {
            user.username => user.email,
            exporter.username => exporter.email
          }
        }.with_indifferent_access
      }

      let(:converted_record_with_roles) {
        described_class.new(
          generic_file, collection_store.data, role_store.data
        )
      }

      it "adds data" do
        expect(
          converted_record_with_roles.send(:file_permissions)
        ).to eql(expected_permissions)
      end
    end
  end

  describe "#list_collections" do
    before do
      make_collection(user, title: "Community", id: "community-1",
                      member_ids: [generic_file.id])
    end

    context "with one collection" do
      before do
        collection_store.build_collection_store_data
        collection_store.build_paths_for_collection_store
      end

      let(:expected_communities) {
        [
          [{"title": "Community", "id": "community-1"}]
        ]
      }

      let(:converted_record_with_collection) {
        described_class.new(
          generic_file, collection_store.data, role_store.data
        )
      }

      it "adds data" do
        expect(
          converted_record_with_collection.send(:list_collections)
        ).to eql(expected_communities)
      end
    end

    context "with two collections" do
      before do
        make_collection(user, title: "Collection", id: "collection-1",
                        member_ids: [generic_file.id])
        collection_store.build_collection_store_data
        collection_store.build_paths_for_collection_store
      end

      let(:expected_communities) {
        [
          [{"title": "Community", "id": "community-1"}],
          [{"title": "Collection", "id": "collection-1"}]
        ]
      }
      let(:converted_record_with_two_collections) {
        described_class.new(
          generic_file, collection_store.data, role_store.data
        )
      }

      it "adds data" do
        expect(
          converted_record_with_two_collections.send(:list_collections)
        ).to eq(expected_communities)
      end
    end

    context "with parent collection" do
      before do
        make_collection(user, title: "Parent", id: "parent-1",
                        member_ids: ["community-1"])
        collection_store.build_collection_store_data
        collection_store.build_paths_for_collection_store
      end

      let(:expected_communities) {
        [
          [
            {"title": "Parent", "id": "parent-1"},
            {"title": "Community", "id": "community-1"}
          ]
        ]
      }

      let(:converted_record_with_parent_collection) {
        described_class.new(
          generic_file, collection_store.data, role_store.data
        )
      }

      it "adds data" do
        expect(
          converted_record_with_parent_collection.send(:list_collections)
        ).to eq(expected_communities)
      end
    end

    context "with multiple parents collection" do
      before do
        make_collection(user, title: "Mom", id: "parent-1",
                        member_ids: ["community-1"])
        make_collection(user, title: "Dad", id: "parent-2",
                        member_ids: ["community-1"])
        collection_store.build_collection_store_data
        collection_store.build_paths_for_collection_store
      end

      let(:expected_communities) {
        [
          [{"title": "Mom", "id": "parent-1"},
           {"title": "Community", "id": "community-1"}],
          [{"title": "Dad", "id": "parent-2"},
           {"title": "Community", "id": "community-1"}]
        ]
      }

      let(:converted_record_with_multiple_parents) {
        described_class.new(
          generic_file, collection_store.data, role_store.data
        )
      }

      it "adds data" do
        expect(
          converted_record_with_multiple_parents.send(:list_collections)
        ).to eq(expected_communities)
      end
    end
  end

  describe "#funding" do
    context "file has no funding data" do
      let(:no_funding_file_id) { "this-is-not-a-file-id" }

      it "returns empty array" do
        expect(invenio_rdm_record_converter.send(:funding, no_funding_file_id)).to eq([])
      end
    end

    context "file has multiple funding sources" do
      let(:multiple_funding_file_id) { "9z902z89q" }

      it "returns all funding sources" do
        expect(invenio_rdm_record_converter.send(:funding, multiple_funding_file_id).length).to eq(2)
      end
    end

    context "file has blank funding sources" do
      let(:blank_funding_file_id) { "78254bed-92a7-4708-bcff-16383bab9ce3" }

      it "returns blank array" do
        expect(invenio_rdm_record_converter.send(:funding, blank_funding_file_id)).to eq([])
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
      "id": "cc-by-3.0-us",
      "link": creative_commons_attribution_v3_url,
      "title": {"en": "Creative Commons Attribution 3.0 United States"}
    }]
  end

  let(:creative_commons_zero_url) { "http://creativecommons.org/publicdomain/zero/1.0/" }
  let(:expected_creative_commons_zero) do
    [{
      "id": "cc0-1.0",
      "link": creative_commons_zero_url,
      "title": {"en": "Creative Commons Zero v1.0 Universal"}
    }]
  end

  let(:mit_license_url) { "https://opensource.org/licenses/MIT" }
  let(:expected_mit) do
    [{
      "id": "mit",
      "link": mit_license_url,
      "title": {"en": "MIT License"}
    }]
  end

  let(:all_rights_reserved) { 'All rights reserved' }
  let(:expected_all_rights_reserved) do
    [{
      "id": "galter-arr-1.0",
      "title": {"en": all_rights_reserved}
    }]
  end

  let(:multiple_rights) { ["https://opensource.org/licenses/MIT", "http://creativecommons.org/publicdomain/zero/1.0/"] }
  let(:expected_multiple_rights) do
    [{
      "id": "mit",
      "link": mit_license_url,
      "title": {"en": "MIT License"}
    },
    {
      "id": "cc0-1.0",
      "link": creative_commons_zero_url,
      "title": {"en": "Creative Commons Zero v1.0 Universal"}
    }]
  end

  describe "#rights" do
    it 'returns the expected license information' do
      expect(invenio_rdm_record_converter.send(:rights, [creative_commons_attribution_v3_url])).to eq(expected_creative_commons_attribution_v3)
      expect(invenio_rdm_record_converter.send(:rights, [creative_commons_zero_url])).to eq(expected_creative_commons_zero)
      expect(invenio_rdm_record_converter.send(:rights, [mit_license_url])).to eq(expected_mit)
      expect(invenio_rdm_record_converter.send(:rights, [all_rights_reserved])).to eq(expected_all_rights_reserved)
      expect(invenio_rdm_record_converter.send(:rights, multiple_rights)).to eq(expected_multiple_rights)
    end
  end

  let(:doi) { "10.18131/g3-hgs7-ag90" }
  let(:doi_org_url) { "https://doi.org/#{doi}" }
  let(:dx_doi_org_url) { "https://dx.doi.org/10.6084/m9.figshare.2002149" }
  let(:non_doi_url) { "www.google.com" }

  describe "#doi_url?" do
    it 'returns true for urls that include doi.org' do
      expect(invenio_rdm_record_converter.send(:doi_url?, doi_org_url)).to eq(true)
      expect(invenio_rdm_record_converter.send(:doi_url?, dx_doi_org_url)).to eq(true)
      expect(invenio_rdm_record_converter.send(:doi_url?, non_doi_url)).to eq(false)
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
        expect(invenio_rdm_record_converter.send(:related_identifiers, [])).to eq([])
      end
    end

    context 'with related_url' do
      it 'returns formatted json' do
        expect(invenio_rdm_record_converter.send(:related_identifiers, [doi_org_url])).to eq([expected_doi_related_identifiers_json])
        expect(invenio_rdm_record_converter.send(:related_identifiers, [non_doi_url])).to eq([expected_related_identifiers_json])
      end
    end
  end

  let(:blank_text_field) { [""] }
  let(:white_space) {[" "]}
  let(:multiple_blanks) {["", " "]}
  let(:one_cat) {["One Cat"]}
  let(:one_cat_with_blank) {["One Cat", ""]}
  let!(:two_cats) {["One Cat", "Two Cats"]}
  let(:two_cats_with_blank) {["One Cat", "Two Cats", ""]}
  let(:expected_two_cats_title) {
    [{
      "title": "Two Cats",
      "type": {"id": "alternative-title"}
    }]
  }
  let(:expected_two_cats_description) {
    [{
      "description": "Two Cats",
      "type": {"id": "other"}
    }]
  }

  describe '#format_additional' do
    context "blank results" do
      it 'returns empty array' do
        expect(invenio_rdm_record_converter.send(:format_additional, "title", "alternative-title", blank_text_field.drop(1))).to eq([])
        expect(invenio_rdm_record_converter.send(:format_additional, "title", "alternative-title", white_space.drop(1))).to eq([])
        expect(invenio_rdm_record_converter.send(:format_additional, "title", "alternative-title", multiple_blanks.drop(1))).to eq([])
        expect(invenio_rdm_record_converter.send(:format_additional, "description", "other", blank_text_field.drop(1))).to eq([])
        expect(invenio_rdm_record_converter.send(:format_additional, "description", "other", white_space.drop(1))).to eq([])
        expect(invenio_rdm_record_converter.send(:format_additional, "description", "other", multiple_blanks.drop(1))).to eq([])
      end
    end

    context "with one cat" do
      it 'returns empty array' do
        expect(invenio_rdm_record_converter.send(:format_additional, "title", "alternative-title", one_cat.drop(1))).to eq([])
        expect(invenio_rdm_record_converter.send(:format_additional, "title", "alternative-title", one_cat_with_blank.drop(1))).to eq([])
        expect(invenio_rdm_record_converter.send(:format_additional, "description", "other", one_cat.drop(1))).to eq([])
        expect(invenio_rdm_record_converter.send(:format_additional, "description", "other", one_cat_with_blank.drop(1))).to eq([])
      end
    end

    context "with two cats" do
      it 'returns array with values' do
        expect(invenio_rdm_record_converter.send(:format_additional, "title", "alternative-title", two_cats.drop(1))).to eq(expected_two_cats_title)
        expect(invenio_rdm_record_converter.send(:format_additional, "title", "alternative-title", two_cats_with_blank.drop(1))).to eq(expected_two_cats_title)
        expect(invenio_rdm_record_converter.send(:format_additional, "description", "other", two_cats.drop(1))).to eq(expected_two_cats_description)
        expect(invenio_rdm_record_converter.send(:format_additional, "description", "other", two_cats_with_blank.drop(1))).to eq(expected_two_cats_description)
      end
    end
  end

  describe "#format_dates" do
    context "file has empty string for dated created" do
      it "returns empty array" do
        expect(invenio_rdm_record_converter.send(:format_dates, [""])).to eq([])
      end
    end
  end

  describe "#normalize_date" do
    context "formatted date" do
      let(:expected_formatted_date_1){ "1907-09-06" }
      let(:expected_formatted_date_2){ "1920-12-01" }
      let(:date_without_zero_padding_1){ "1907-9-6" }
      let(:date_without_zero_padding_2){ "1920-12-1" }
      let(:date_with_dashes){ expected_formatted_date_1 }
      let(:date_with_slashes){ "1907/09/06" }
      let(:date_starts_with_month_padded){ "09/06/1907" }
      let(:date_starts_with_month_zero_padding){ "9/6/1907" }

      it "normalizes date" do
        expect(invenio_rdm_record_converter.send(:normalize_date, date_without_zero_padding_1)).to eq(expected_formatted_date_1)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_without_zero_padding_2)).to eq(expected_formatted_date_2)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_dashes)).to eq(expected_formatted_date_1)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_slashes)).to eq(expected_formatted_date_1)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_starts_with_month_padded)).to eq(expected_formatted_date_1)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_starts_with_month_zero_padding)).to eq(expected_formatted_date_1)
      end
    end

    context "month first date" do
      let(:expected_formatted_date_1){ "1927-09-06" }
      let(:expected_formatted_date_2){ "2007-09-06" }

      let(:padded_date){ "09/06/1927" }
      let(:unpadded_date){ "9/6/1927" }

      it "normalizes date" do
        expect(invenio_rdm_record_converter.send(:normalize_date, padded_date)).to eq(expected_formatted_date_1)
        expect(invenio_rdm_record_converter.send(:normalize_date, unpadded_date)).to eq(expected_formatted_date_1)
      end
    end

    context "date with month and year only" do
      let(:date_with_dashes_month_only){ "1903-06" }
      let(:date_with_slashes_month_only){ "1903/06" }
      let(:date_with_month_first){ "06/1903" }

      it "normalizes date with year and month available" do
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_dashes_month_only)).to eq(date_with_dashes_month_only)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_slashes_month_only)).to eq(date_with_dashes_month_only)
        expect(invenio_rdm_record_converter.send(:normalize_date, date_with_month_first)).to eq(date_with_dashes_month_only)
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

    context "seasonal name" do
      let(:two_seasonal_names){ "Spring/Summer 1995" }
      let(:single_seasonal_name){ "Spring 2001" }

      it "ignores seasonal names" do
        expect(invenio_rdm_record_converter.send(:normalize_date, two_seasonal_names)).to eq("")
        expect(invenio_rdm_record_converter.send(:normalize_date, single_seasonal_name)).to eq("")
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

  describe "#subjects_for_field" do
    context "mesh scheme" do
      let(:unknown_mesh_term){ ["nothing but lies"] }
      let(:known_mesh_term){ ["Bile Duct Neoplasms"] }
      let(:known_mesh_term_with_qualifier){ ["Burkitt Lymphoma--etiology"] }
      let(:mesh_subject_type){ :mesh }
      let(:expected_mesh_result){ [{"id": "https://id.nlm.nih.gov/mesh/D001650"}]}
      let(:expected_mesh_with_qualifier_result){ [{"id": "https://id.nlm.nih.gov/mesh/D002051Q000209"}]}

      it "returns '[]' for unknown term" do
        expect(invenio_rdm_record_converter.send(:subjects_for_field, unknown_mesh_term, mesh_subject_type)).to eq([])
      end

      it "returns metadata for known term without qualifier" do
        expect(invenio_rdm_record_converter.send(:subjects_for_field, known_mesh_term, mesh_subject_type)).to eq(expected_mesh_result)
      end

      it "returns metadata for term with qualifier" do
        expect(invenio_rdm_record_converter.send(:subjects_for_field, known_mesh_term_with_qualifier, mesh_subject_type)).to eq(expected_mesh_with_qualifier_result)
      end
    end

    context "lcsh scheme" do
      let(:unknown_lcsh_term){ ["nothing but lies"] }
      let(:known_lcsh_term){ ["Abdomen--Cancer"] }
      let(:lcsh_subject_type){ :lcsh }
      let(:expected_lcsh_result){ ["id": "http://id.loc.gov/authorities/subjects/sh85000095"] }

      it "returns '[]' for unknown term" do
        expect(invenio_rdm_record_converter.send(:subjects_for_field, unknown_lcsh_term, lcsh_subject_type)).to eq([])
      end

      it "returns metadata for known term" do
        expect(invenio_rdm_record_converter.send(:subjects_for_field, known_lcsh_term, lcsh_subject_type)).to eq(expected_lcsh_result)
      end
    end

    context "subject_name scheme" do
      let(:subject_name_term){ ["malignant"] }
      let(:subject_name_subject_type){ :subject_name }
      let(:expected_subject_name_result){ [] }

      it "returns metadata for known term" do
        expect(invenio_rdm_record_converter.send(:subjects_for_field, subject_name_term, subject_name_subject_type)).to eq(expected_subject_name_result)
      end
    end

    context "lcnaf scheme" do
      let(:subject_name_terms) { [lcnaf_term] }
      let(:subject_name_subject_type){ :subject_name }
      let(:expected_lcnaf_pid) { ["id": "http://id.loc.gov/authorities/names/n90699999"] }


      it "returns metadata for term" do
        expect(invenio_rdm_record_converter.send(:subjects_for_field, subject_name_terms, subject_name_subject_type)).to eq(expected_lcnaf_pid)
      end
    end

    context "tag scheme" do
      let(:tag_term) { "Galter Health Sciences Library" }
      let(:tag_terms) { [tag_term] }
      let(:expected_tag_result){ [{"subject": tag_term}] }

      it "returns the tag in subject field" do
        expect(invenio_rdm_record_converter.send(:subjects_for_field, tag_terms, :tag)).to eq(expected_tag_result)
      end
    end
  end

  describe "#dh_collection_to_prism_community_collection" do
    let(:map_collection_to_prism_community_collections_irrc) { described_class.new(generic_file, collection_store.data) }
    let(:expected_community_collection_string_2019_2020) { "biostatistics-collaboration-center-lecture-series::2019-2020" }
    let(:expected_community_collection_string_center_for_community_health) { "center-for-community-health" }

    let(:generic_file_with_community_collection_match) { make_generic_file_with_content(user, id: "9e27fbd0-c6cb-47c7-8770-8ffeb135009d") }
    let(:expected_community_collection_string_center_for_file_id) { "science-in-society-scientific-images-contest::2018 Scientific Images Contest Winners" }
    let(:map_file_to_prism_community_collections_irrc) { described_class.new(generic_file_with_community_collection_match, collection_store.data) }

    let!(:collection_pnb) { make_collection(user, title: "Pediatric Neurology Briefs: Volume 05 Issue 07", id: "pnb-5-7", member_ids: [generic_file_pnb.id]) }
    let(:generic_file_pnb) { make_generic_file_with_content(user, id: "pnb-5-7-20") }
    let(:expected_pnb_community_string) { "pediatric-neurology-briefs::Volume 05, Issue 07" }
    let!(:collection_pnb_short_id) { make_collection(user, title: "Pediatric Neurology Briefs: Volume 01", id: "pnb-1", member_ids: [generic_file_pnb_with_short_id.id]) }
    let(:generic_file_pnb_with_short_id) { make_generic_file_with_content(user, id: "pnb-5") }
    let(:expected_pnb_short_id_community_string) { "pediatric-neurology-briefs::Volume 01" }

    let(:generic_file_converter_pnb) { described_class.new(generic_file_pnb, collection_store.data) }
    let(:generic_file_converter_pnb_short_id) { described_class.new(generic_file_pnb_with_short_id, collection_store.data) }

    context "there is not a match in the collection store or the filed id to prism commmunity communities mapping json" do
      before do
        # clear the existing collections
        collection_store.build_collection_store_data
        collection_store.build_paths_for_collection_store
      end

      it "returns a blank string" do
        expect(map_collection_to_prism_community_collections_irrc.send(:dh_collection_to_prism_community_collection)).to eq("")
      end
    end

    context "file belongs to pediatric neurology brief collection" do
      before do
        collection_store.build_collection_store_data
        collection_store.build_paths_for_collection_store
      end

      context "for a pnb generic file" do
        context "that belongs to a collection with an issue number in the id" do
          it "returns the correct community string" do
            expect(generic_file_converter_pnb.send(:dh_collection_to_prism_community_collection)).to eq(expected_pnb_community_string)
          end
        end

        context "that belongs to a collection without an issue number in the collection id" do
          it "returns the correct community string" do
            expect(generic_file_converter_pnb_short_id.send(:dh_collection_to_prism_community_collection)).to eq(expected_pnb_short_id_community_string)
          end
        end
      end
    end

    context "there are matches in the collection store to prism community collections mapping json for community and collection" do
      before do
        make_collection(user, title: "2019-2020", id: "a86e1412-d72c-4cae-b8ca-16fd834cb128", member_ids: [generic_file.id])

        collection_store.build_collection_store_data
        collection_store.build_paths_for_collection_store
      end

      it "returns correctly formatted string" do
        expect(map_collection_to_prism_community_collections_irrc.send(:dh_collection_to_prism_community_collection)).to eq(expected_community_collection_string_2019_2020)
      end
    end

    context "there are matches in the collection store to prism community collections mapping json for community only" do
      before do
        make_collection(user, title: "Center for Community Health", id: "ae0b945c-d0d4-45bb-a0fc-263c7afca49e", member_ids: [generic_file.id])

        collection_store.build_collection_store_data
        collection_store.build_paths_for_collection_store
      end

      it "returns correctly formatted string" do
        expect(map_collection_to_prism_community_collections_irrc.send(:dh_collection_to_prism_community_collection)).to eq(expected_community_collection_string_center_for_community_health)
      end
    end

    context "the file id matches to prism commnity collections mapping json" do
      it "returns correctly formatted string" do
        expect(map_file_to_prism_community_collections_irrc.send(:dh_collection_to_prism_community_collection)).to eq(expected_community_collection_string_center_for_file_id)
      end
    end
  end

  describe "owner_info" do
    let(:josh_elder_user) { FactoryGirl.create(:user, username: "josh_the_elder", formal_name: "Elder, Josh",  display_name: 'Josh Elder', email: 'joshelder@northwestern.edu') }

    it "identifies Josh Elder's email and returns the correct casing" do
      expect(invenio_rdm_record_converter.send(:owner_info, josh_elder_user.username)).to eq({'josh_the_elder' => 'JoshElder@northwestern.edu'})
    end
  end

  describe "sizes" do
    it "returns a blank array when page_count is blank" do
      allow(generic_file).to receive(:page_count).and_return(nil)
      expect(invenio_rdm_record_converter.send(:sizes)).to eq([])
    end
  end
end
