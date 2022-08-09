require 'rails_helper'

RSpec.describe HeaderLookup do
  let(:mesh_term) { "Vocabulary, Controlled" }
  let(:no_pid_mesh_subject) { "Fake Mesh Term: DigitalHub field mesh" }
  let(:no_pid_lcsh_subject) { "Fake Lcsh Term: DigitalHub field lcsh" }

  let(:lcsh_local_subject) { "Cancer" }
  let(:expected_lcsh_local_subject) { "http://id.loc.gov/authorities/subjects/sh85019492" }

  let(:mesh_local_subject) { "Abrin" }
  let(:expected_mesh_local_subject) { "https://id.nlm.nih.gov/mesh/D000036" }

  let(:lcnaf_term) { "Birkan, Kaarin" }
  let(:expected_lcnaf_id) { "http://id.loc.gov/authorities/names/n90699999" }

  describe "#pid_lookup_by_field" do
    context "nil values" do
      it 'returns nil for an lcsh subject header with no pid' do
        expect(subject.send(:pid_lookup_by_field, no_pid_lcsh_subject, :lcsh)).to eq(nil)
      end

      it 'returns nil for a mesh subject header with no pid' do
        expect(subject.send(:pid_lookup_by_field, no_pid_mesh_subject, :mesh)).to eq(nil)
      end
    end

    context "lcsh term" do
      it "returns expected pid" do
        expect(subject.send(:pid_lookup_by_field, lcsh_local_subject, :lcsh)).to eq(expected_lcsh_local_subject)
      end
    end

    context "mesh term" do
      it "returns expected pid" do
        expect(subject.send(:pid_lookup_by_field, mesh_local_subject, :mesh)).to eq(expected_mesh_local_subject)
      end
    end

    context "lcnaf term" do
      it "it returns the correct id for the lcnaf term" do
        expect(subject.send(:pid_lookup_by_field, lcnaf_term, :subject_name)).to eq(expected_lcnaf_id)
      end
    end
  end
end
