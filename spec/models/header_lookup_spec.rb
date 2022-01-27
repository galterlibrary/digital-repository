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
  let(:expected_mesh_result) { "https://id.nlm.nih.gov/mesh/D018875" }
  let(:expected_memoized_mesh) { {mesh_term=>expected_mesh_result} }
  let(:blank_mesh_term) { "mesh term does not exist" }
  let(:expected_failed_mesh) { "#{blank_mesh_term} - MESH" }

  describe "#mesh_term_pid_lookup" do
    context 'search returns values' do
      before do
        allow(HTTParty).to receive(:get).and_return(mesh_api_response)
        @mesh_result = subject.mesh_term_pid_lookup(mesh_term)
      end

      it 'calls api with correct term' do
        expect(HTTParty).to have_received(:get).with(mesh_query_url)
      end

      it 'returns result for mesh term' do
        expect(@mesh_result).to eq(expected_mesh_result)
      end
    end

    context 'search returns no values' do
      before do
        allow(HTTParty).to receive(:get).and_return(empty_mesh_api_response)
        @mesh_result = subject.mesh_term_pid_lookup(blank_mesh_term)
      end

      it 'returns N/A for PID for mesh term' do
        expect(@mesh_result).to eq(nil)
      end
    end
  end

  let(:lcsh_term) { "Semantic Web" }
  let(:lcsh_query_url) { "http://id.loc.gov/authorities/subjects/suggest/?q=*Semantic+Web*" }
  let(:lcsh_api_response) do
    """\
    [\"*Semantic*Web*\",[\"Semantic Web\",\"Semantic Web--Congresses\"],[\"1 result\",\"1 result\"],[\"http://id.loc.go\
    v/authorities/subjects/sh2002000569\",\"http://id.loc.gov/authorities/subjects/sh2010112582\"]]
    """
  end
  let(:empty_lcsh_api_response) { "[\"*this*is*not*a*real*search*\",[],[],[]]" }
  let(:expected_lcsh_result) { "https://id.loc.gov/authorities/subjects/sh2002000569" }
  let(:expected_memoized_lcsh) { {lcsh_term=>expected_lcsh_result} }
  let(:blank_lcsh_term) { "lcsh term does not exist" }
  let(:expected_failed_lcsh) { "#{blank_lcsh_term} - LCSH" }

  describe "#lcsh_term_pid_lookup" do
    context 'search returns values' do
      before do
        allow(HTTParty).to receive(:get).and_return(lcsh_api_response)
        @lcsh_result = subject.lcsh_term_pid_lookup(lcsh_term)
      end

      it 'calls api with correct term' do
        expect(HTTParty).to have_received(:get).with(lcsh_query_url)
      end

      # TODO figure out what to do with terms that have multiple PIDs returned from query
      it 'returns result for lcsh term' do
        expect(@lcsh_result).to eq(expected_lcsh_result)
      end
    end

    context 'search returns no values' do
      before do
        allow(HTTParty).to receive(:get).and_return(empty_lcsh_api_response)
        @lcsh_result = subject.lcsh_term_pid_lookup(lcsh_term)
      end

      it 'returns nil for PID for lcsh term' do
        expect(@lcsh_result).to eq(nil)
      end
    end
  end

  let(:no_pid_mesh_subject) { "Fake Mesh Term: DigitalHub field mesh" }
  let(:no_pid_lcsh_subject) { "Fake Lcsh Term: DigitalHub field lcsh" }

  # TODO: do we want this to return nil? Should we log these values somewhere?
  describe "#pid_lookup_by_scheme" do
    it 'returns nil for subject header with no pid' do
      expect(subject.send(:pid_lookup_by_scheme, no_pid_lcsh_subject, :lcsh)).to eq(nil)
    end

    it 'returns nil for subject header with no pid' do
      expect(subject.send(:pid_lookup_by_scheme, no_pid_mesh_subject, :mesh)).to eq(nil)
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

  let(:lcnaf_file_name) { "spec/fixtures/mock_lcnaf.yml" }
  let(:lcnaf_term) { "New York (N.Y.). Administration for Children's Services" }
  let(:lcnaf_id) { "http://id.loc.gov/authorities/names/n2001099999" }
  let(:lcnaf_term2) { "Birkan, Kaarin" }
  let(:lcnaf_id2) { "http://id.loc.gov/authorities/names/n90699999" }

  describe "#lcnaf_pid_lookup" do
    it "it returns the correct id for the lcnaf term" do
      expect(subject.lcnaf_pid_lookup(lcnaf_term, lcnaf_file_name)).to eq(lcnaf_id)
      expect(subject.lcnaf_pid_lookup(lcnaf_term2, lcnaf_file_name)).to eq(lcnaf_id2)
    end
  end
end
