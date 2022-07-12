require 'rails_helper'

RSpec.describe HeaderLookup do
  let(:mesh_term) { "Vocabulary, Controlled" }
  let(:mesh_query_url) do
    "https://id.nlm.nih.gov/mesh/sparql?format=JSON&limit=10&inference=true&query=PREFIX%20rdfs%3A%20%3Chttp%3A%2F%2Fwww"\
    ".w3.org%2F2000%2F01%2Frdf-schema%23%3E%0D%0APREFIX%20meshv%3A%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%2Fvocab%23%3E"\
    "%0D%0APREFIX%20mesh2018%3A%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0A%0D%0ASELECT%20%3Fd%20%3FdName%0D%0AFROM"\
    "%20%3Chttp%3A%2F%2Fid.nlm.nih.gov%2Fmesh%3E%0D%0AWHERE%20%7B%0D%0A%20%20%3Fd%20a%20meshv%3ADescriptor%20.%0D%0A%20%"\
    "20%3Fd%20rdfs%3Alabel%20%3FdName%0D%0A%20%20FILTER(REGEX(%3FdName%2C%27Vocabulary%2C+Controlled%27%2C%20%27i%27))%2"\
    "0%0D%0A%7D%20%0D%0AORDER%20BY%20%3Fd%20%0D%0A"
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
  let(:empty_mesh_api_response) do
    "{
     \"head\": {
       \"vars\": [ \"d\" , \"dName\" ]
       } ,
       \"results\": {
           \"bindings\": [
           ]
       }
     }"
  end

  let(:no_pid_mesh_subject) { "Fake Mesh Term: DigitalHub field mesh" }
  let(:no_pid_lcsh_subject) { "Fake Lcsh Term: DigitalHub field lcsh" }

  describe "#pid_lookup_by_field" do
    it 'returns nil for subject header with no pid' do
      expect(subject.send(:pid_lookup_by_field, no_pid_lcsh_subject, :lcsh)).to eq(nil)
    end

    it 'returns nil for subject header with no pid' do
      expect(subject.send(:pid_lookup_by_field, no_pid_mesh_subject, :mesh)).to eq(nil)
    end
  end

  let(:lcsh_local_subject) { "Cancer" }
  let(:expected_lcsh_local_subject) { "http://id.loc.gov/authorities/subjects/sh85019492" }

  describe "#lcsh_term_pid_local_lookup" do
    it "returns expected pid" do
      expect(subject.lcsh_term_pid_local_lookup(lcsh_local_subject)).to eq(expected_lcsh_local_subject)
    end
  end

  let(:mesh_local_subject) { "Abrin" }
  let(:expected_mesh_local_subject) { "https://id.nlm.nih.gov/mesh/D000036" }

  describe "#mesh_term_pid_local_lookup" do
    it "returns expected pid" do
      expect(subject.mesh_term_pid_local_lookup(mesh_local_subject)).to eq(expected_mesh_local_subject)
    end
  end

  let(:lcnaf_term) { "Birkan, Kaarin" }
  let(:lcnaf_id) { "http://id.loc.gov/authorities/names/n90699999" }

  describe "#lcnaf_pid_lookup" do
    it "it returns the correct id for the lcnaf term" do
      expect(subject.lcnaf_pid_lookup(lcnaf_term)).to eq(lcnaf_id)
    end
  end
end
