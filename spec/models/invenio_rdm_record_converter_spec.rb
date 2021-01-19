require 'rails_helper'

RSpec.describe InvenioRdmRecordConverter do
  let(:user) { FactoryGirl.create(:user, username: "usr1234", formal_name: "Tester, Mock", orcid: "https://orcid.org/1234-5678-9123-4567",
                                    display_name: 'Mock Tester') }
  let(:assistant) { FactoryGirl.create(:user, username: "ast9876") }

  before do
    ProxyDepositRights.create(grantor_id: assistant.id, grantee_id: user.id)
  end

  let(:generic_file) {
    make_generic_file(
      user,
      doi: ["doi:123/ABC"],
      resource_type: ["Account Books"],
      proxy_depositor: assistant.username,
      on_behalf_of: user.username,
      creator: [user.formal_name]
    )
  }

  let(:json) do
    {
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
        }]
      },
      "provenance": {
        "created_by": {
          "user": assistant.username
        },
        "on_behalf_of": {
          "user": user.username
        }
      }
    }.to_json
  end

  describe "#to_json" do
    subject { described_class.new(generic_file).to_json }

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
end
