require 'rails_helper'

RSpec.describe InvenioRdmRecordConverter do
  let(:user) { FactoryGirl.create(:user, username: "usr1234", formal_name: "Tester, Mock", orcid: "https://orcid.org/1234-5678-9123-4567", \
                                    display_name: 'Mock Tester') }
  let(:assistant) { FactoryGirl.create(:user, username: "ast9876") }
  let(:mesh_term) { "Vocabulary, Controlled" }
  let(:expected_mesh_pid) { "D018875" }
  let(:lcsh_term) { "Semantic Web" }
  let(:expected_lcsh_pid) { "sh2002000569" }
  let(:generic_file) {
    make_generic_file(
      user,
      doi: ["doi:123/ABC"],
      resource_type: ["Account Books"],
      proxy_depositor: assistant.username,
      on_behalf_of: user.username,
      creator: [user.formal_name],
      title: ["Primary Title"],
      tag: ["keyword subject"],
      publisher: ["DigitalHub. Galter Health Sciences Library & Learning Center"],
      date_uploaded: Time.new(2020, 2, 3),
      mesh: [mesh_term],
      lcsh: [lcsh_term],
      mime_type: 'application/pdf',
      based_near: ["'Boston, Massachusetts, United States', 'East Peoria, Illinois, United States'"],
      description: ["This is a generic file for specs only", "This is an additional description to help test"],
      date_created: ["1-1-2021"]
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
            "type": "Books",
            "subtype": "Account Book"
          },
          "creators": [{
            "name": "#{user.formal_name}",
            "type": "personal",
            "role": "",
            "given_name": "#{user.display_name.split.first}",
            "family_name": "#{user.display_name.split.last}",
            "identifiers": {
              "orcid": "#{user.orcid.split('/').last}"
            },
            "affiliations": []
          }],
          "title": "#{generic_file.title.first}",
          "additional_titles": [
            {
              "title": "Secondary Title",
              "type": "alternative_title",
              "lang": "eng"
            },
            {
              "title": "Tertiary Title",
              "type": "alternative_title",
              "lang": "eng"
            }
          ],
          "description": generic_file.description.shift,
          "additional_descriptions": [{"description": generic_file.description.last, "type": "other", "lang": "eng"}],
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
          "dates": [{"date": "1-1-2021", "type": "other", "description": "When the item was originally created."}],
          "formats": "application/pdf",
          "locations": [{"place": "Boston, Massachusetts, United States"}, {"place": "East Peoria, Illinois, United States"}]
        },
        "provenance": {
          "created_by": {
            "user": assistant.username
          },
          "on_behalf_of": {
            "user": user.username
          }
        }
      },
      "file": {
        "filename": generic_file.filename,
        "content_path": nil # there is no file/content attached with this factory made GewnericFile
      }
    }.to_json
  end

  before do
    ProxyDepositRights.create(grantor_id: assistant.id, grantee_id: user.id)
    # ensure order of titles is consistent by updating generic file with additional titles after creation
    generic_file.title << ["Secondary Title", "Tertiary Title"]
  end

  describe "#to_json" do
    subject { described_class.new(generic_file).to_json } #(except: [:memoized_mesh, :memoized_lcsh]) }

    it do
      is_expected.to eq json
    end
  end

  let(:converter) { InvenioRdmRecordConverter.new }
  let(:non_user_creator_name) { "I Don't Exist" }
  let(:personal_creator_without_user_json) {
    {
      "creators": [{
          "name": non_user_creator_name,
          "type": "personal",
          "role": "",
          "given_name": "",
          "family_name": "",
          "identifiers": {},
          "affiliations": []
        }]
    }
  }.to_json

  let(:unidentified_creator_name) { "Creator not identified." }
  let(:personal_creator_unknown_json) {
    {
      "creators": [{
          "name": "",
          "type": "personal",
          "role": "",
          "given_name": "",
          "family_name": "",
          "identifiers": {},
          "affiliations": []
        }]
    }
  }.to_json

  let(:organization_name) { "Galter Health Sciences Library" }
  let(:organizational_creator_json) {
    {
      "creators": [{
          "name": organization_name,
          "type": "organisational",
          "role": "",
          "given_name": "",
          "family_name": "",
          "identifiers": {},
          "affiliations": []
        }]
    }
  }.to_json

  describe "#creators" do
    context 'personal record without user in digital hub' do
      it 'assigns' do
        expect({creators: converter.send(:creators, [non_user_creator_name])}).to eq(personal_creator_without_user_json)
      end
    end

    context 'personal record with unidentified user' do
      it 'assigns' do
        expect({creators: converter.send(:creators, [unidentified_creator_name])}).to eq(personal_creator_unknown_json)
      end
    end

    context 'organizational record' do
      it 'assigns' do
        expect({creators: converter.send(:creators, [organization_name])}).to eq(organizational_creator_json)
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
end
