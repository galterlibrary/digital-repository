require 'rails_helper'

describe AddInstitutionalAdminPermissionsJob do
  let(:user) { create(:user) }
  let!(:gf1) { make_generic_file(user, id: 'gf1') }
  let!(:col1) { make_collection(
    user, id: 'col1', institutional_collection: true) }

  subject { described_class.new('gf1', 'col1') }

  it 'runs the job' do
    expect(subject.object).to receive(
      :add_institutional_admin_permissions).with('col1')
    subject.run
  end
end
