require 'rails_helper'

describe CreateDerivativesJob do
  let(:gf1) { make_generic_file(create(:user), id: 'gf1') }

  subject { described_class.new(gf1.id) }

  before do
    gf1.label = 'test1.png'
    gf1.date_uploaded = DateTime.now
    gf1.add_file(
      File.open(Rails.root.join('spec/fixtures/test1.png')),
      original_name: 'test1.png',
      path: 'content',
      mime_type: 'image/png'
    )
    gf1.save!
  end

  it 'updates the modified_date' do
    expect(subject.object).to receive(:create_derivatives)
    old_mod_date = subject.object.modified_date
    subject.run
    expect(subject.object.reload.modified_date).to be > old_mod_date
  end
end
