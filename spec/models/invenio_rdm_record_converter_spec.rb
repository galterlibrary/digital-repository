require 'rails_helper'

RSpec.describe InvenioRdmRecordConverter do
  let(:user) { FactoryGirl.create(:user, username: "usr1234", formal_name: "Tester, Mock", orcid: "https://orcid.org/1234-5678-9123-4567", \
                                    display_name: 'Mock Tester') }
  let(:assistant) { FactoryGirl.create(:user, username: "ast9876") }
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
      mesh: [mesh_term],
      lcsh: [lcsh_term],
      mime_type: 'application/pdf',
      based_near: ["'Boston, Massachusetts, United States', 'East Peoria, Illinois, United States'"]
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

  # TODO move to separate spec, something like spec/models/header_lookup_spec.rb
  let(:mesh_term) { "Vocabulary, Controlled" }
  let(:mesh_query_url) do
    "https://id.nlm.nih.gov/mesh/sparql?format=JSON&limit=10&inference=true&query=PREFIX%20rdfs%3A%20%3Chttp%3A%2F%2Fwww"\
    ".w3.org%2F2000%2F01%2Frdf-schema%23%3E%0D%0APREFIX%20meshv%3A%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%2Fvocab%23%3E"\
    "%0D%0APREFIX%20mesh2018%3A%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0A%0D%0ASELECT%20%3Fd%20%3FdName%0D%0AFROM"\
    "%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0AWHERE%20%7B%0D%0A%20%20%3Fd%20a%20meshv%3ADescriptor%20.%0D%0A%20%"\
    "20%3Fd%20rdfs%3Alabel%20%3FdName%0D%0A%20%20FILTER(REGEX(%3FdName%2C%27Vocabulary, Controlled%27%2C%20%27i%27))%20%0"\
    "D%0A%7D%20%0D%0AORDER%20BY%20%3Fd%20%0D%0A"
  end
  let(:mesh_api_response) do
    "{
      \"head\": {
        \"vars\": [ \"d\" , \"dName\" ]
      } ,
      \"results\": {
          \"bindings\": [
          {
            \"d\": { \"type\": \"uri\" , \"value\": \"http://id.nlm.nih.gov/mesh/D018875\" } ,
            \"dName\": { \"type\": \"literal\" , \"xml:lang\": \"en\" , \"value\": \"Vocabulary, Controlled\" }
          }
        ]
      }
    }"
  end
  let(:expected_mesh_pid) { "D018875" }
  let(:expected_memoized_mesh) { {mesh_term=>expected_mesh_pid} }

  describe "#mesh_term_pid_lookup" do
    before do
      allow(HTTParty).to receive(:get).and_return(mesh_api_response)
      @mesh_pid = converter.mesh_term_pid_lookup(mesh_term)
    end

    it 'calls api with correct term' do
      expect(HTTParty).to have_received(:get).with(mesh_query_url)
    end

    it 'returns PID for mesh term' do
      expect(@mesh_pid).to eq(expected_mesh_pid)
    end

    it 'memoizes the result on success' do
      expect(converter.send(:memoized_mesh_lookups)).to eq(expected_memoized_mesh)
    end
  end

  let(:lcsh_term) { "Semantic Web" }
  let(:lcsh_query_url) { "http://id.loc.gov/authorities/subjects/suggest/?q=*Semantic*Web*" }
  let(:lcsh_api_response) do
    """\
    [\"*Semantic*Web*\",[\"Semantic Web\",\"Semantic Web--Congresses\"],[\"1 result\",\"1 result\"],[\"http://id.loc.go\
    v/authorities/subjects/sh2002000569\",\"http://id.loc.gov/authorities/subjects/sh2010112582\"]]
    """
  end
  let(:expected_lcsh_pid) { "sh2002000569" }
  let(:expected_memoized_lcsh) { {lcsh_term=>expected_lcsh_pid} }

  describe "#lcsh_term_pid_lookup" do
    before do
      allow(HTTParty).to receive(:get).and_return(lcsh_api_response)
      @lcsh_pids = converter.lcsh_term_pid_lookup(lcsh_term)
    end

    it 'calls api with correct term' do
      expect(HTTParty).to have_received(:get).with(lcsh_query_url)
    end

    # TODO figure out what to do with terms that have multiple PIDs returned from query
    it 'returns PID for lcsh term' do
      expect(@lcsh_pids).to eq(expected_lcsh_pid)
    end

    it 'memoizes the result on success' do
      expect(converter.send(:memoized_lcsh_lookups)).to eq(expected_memoized_lcsh)
    end
  end
end
