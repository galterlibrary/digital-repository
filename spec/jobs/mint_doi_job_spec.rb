require 'rails_helper'

describe MintDoiJob do
  let(:user) { create(:user) }
  let!(:gf1) { make_generic_file(user, id: 'gf1') }

  subject { described_class.new('gf1') }

  it 'runs the job' do
    expect(subject.object).to receive(:check_doi_presence)
    subject.run
  end
end
