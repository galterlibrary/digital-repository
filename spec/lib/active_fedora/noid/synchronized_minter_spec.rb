require 'rails_helper'
RSpec.describe ActiveFedora::Noid::SynchronizedMinter do
  subject { described_class.new }

  describe '#mint' do
    context '#next_id returns a Fedora tombstone id' do
      before do
        gf = make_generic_file(create(:user), id: 'will_die')
        gf.destroy
      end

      it 'will return a valid id' do
        allow(subject).to receive(:next_id).and_return(
          'will_die', 'not_there')
        expect(subject.mint).to eq('not_there')
      end
    end
  end
end
