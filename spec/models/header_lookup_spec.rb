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
  let(:expected_mesh_pid) { "D018875" }
  let(:expected_memoized_mesh) { {mesh_term=>expected_mesh_pid} }
  let(:blank_mesh_term) { "mesh term does not exist" }
  let(:expected_failed_mesh) { "#{blank_mesh_term} - MESH" }

  describe "#mesh_term_pid_lookup" do
    context 'search returns values' do
      before do
        allow(HTTParty).to receive(:get).and_return(mesh_api_response)
        @mesh_pid = subject.mesh_term_pid_lookup(mesh_term)
      end

      it 'calls api with correct term' do
        expect(HTTParty).to have_received(:get).with(mesh_query_url)
      end

      it 'returns PID for mesh term' do
        expect(@mesh_pid).to eq(expected_mesh_pid)
      end
    end

    context 'search returns no values' do
      before do
        allow(HTTParty).to receive(:get).and_return(empty_mesh_api_response)
        @mesh_pid = subject.mesh_term_pid_lookup(blank_mesh_term)
      end

      it 'returns N/A for PID for mesh term' do
        expect(@mesh_pid).to eq(nil)
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
  let(:expected_lcsh_pid) { "sh2002000569" }
  let(:expected_memoized_lcsh) { {lcsh_term=>expected_lcsh_pid} }
  let(:blank_lcsh_term) { "lcsh term does not exist" }
  let(:expected_failed_lcsh) { "#{blank_lcsh_term} - LCSH" }

  describe "#lcsh_term_pid_lookup" do
    context 'search returns values' do
      before do
        allow(HTTParty).to receive(:get).and_return(lcsh_api_response)
        @lcsh_pids = subject.lcsh_term_pid_lookup(lcsh_term)
      end

      it 'calls api with correct term' do
        expect(HTTParty).to have_received(:get).with(lcsh_query_url)
      end

      # TODO figure out what to do with terms that have multiple PIDs returned from query
      it 'returns PID for lcsh term' do
        expect(@lcsh_pids).to eq(expected_lcsh_pid)
      end
    end

    context 'search returns no values' do
      before do
        allow(HTTParty).to receive(:get).and_return(empty_lcsh_api_response)
        @lcsh_pids = subject.lcsh_term_pid_lookup(lcsh_term)
      end

      it 'returns nil for PID for lcsh term' do
        expect(@lcsh_pids).to eq(nil)
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
end
