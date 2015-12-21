require 'rails_helper'

describe DeactivateDoiJob do
  let(:user) { create(:user, username: 'u1') }
  let(:batch_user) { create(:user, username: 'batch') }
  let(:gf1) { make_generic_file(user, id: 'gf1', title: ['GF Title']) }

  subject { described_class.new(gf1.id, 'doi1', user.username) }

  context 'initialization' do
    describe 'title passed as an argument' do
      subject { described_class.new(gf1.id, 'doi1', 'u1', 'Title') }
      describe 'file exists' do
        it 'sets title to the passed value' do
          expect(subject.title).to eq('Title')
        end
      end

      describe 'file does not exists' do
        subject { described_class.new('badid', 'doi1', 'u1', 'Title') }

        it 'sets title to the passed value' do
          expect(subject.title).to eq('Title')
        end
      end

      describe 'file was deleted' do
        it 'sets title to the passed value' do
          gf1.destroy
          expect(subject.title).to eq('Title')
        end
      end
    end

    describe 'title not passed as an argument' do
      subject { described_class.new(gf1.id, 'doi1', 'u1') }

      describe 'file exists' do
        it 'sets title to the value found in the file' do
          expect(subject.title).to eq('GF Title')
        end
      end

      describe 'file does not exists' do
        subject { described_class.new('badid', 'doi1', 'u1') }

        it 'sets title to the file id' do
          expect(subject.title).to eq('badid')
        end
      end

      describe 'file was deleted' do
        it 'sets title to the file id' do
          gf1.destroy
          expect(subject.title).to eq('gf1')
        end
      end
    end
  end

  context 'status not set in check_doi_presence' do
    it 'does not notify the user of doi action' do
      expect(User).not_to receive(:batchuser)
      subject.run
    end
  end

  context 'status set in deactivate_or_remove_doi' do
    before { expect(User).to receive(:batchuser).and_return(batch_user) }

    describe 'when doi was deactivated' do
      before do
        subject.status = 'deactivated'
      end

      context 'when the file exists' do
        it 'notifies the user of the DOI deactivation and links to the file' do
          subject.run
          expect(user.mailbox.inbox.first.subject).to eq('DOI deactivated')
          expect(user.mailbox.inbox.first.messages.first.body).to include(
            "DOI 'doi1' was deactivated for <a href='/files/gf1'>GF Title")
        end
      end

      context 'when the file does not exist' do
        subject { described_class.new('badid', 'doi1', user.username) }

        it 'notifies the user of the DOI deactivation without a link' do
          gf1.destroy
          subject.run
          expect(user.mailbox.inbox.first.subject).to eq('DOI deactivated')
          expect(user.mailbox.inbox.first.messages.first.body).to include(
            "DOI 'doi1' was deactivated for a deleted object: 'badid'")
        end
      end
    end

    describe 'when doi was deleted' do
      before do
        subject.status = 'deleted'
      end

      context 'when the file exists' do
        it 'notifies the user of the DOI deletion and links to the file' do
          subject.run
          expect(user.mailbox.inbox.first.subject).to eq('DOI deleted')
          expect(user.mailbox.inbox.first.messages.first.body).to include(
            "DOI 'doi1' was removed for <a href='/files/gf1'>")
        end
      end

      context 'when the file does not exist' do
        subject { described_class.new('badid', 'doi1', user.username) }

        it 'notifies the user of the DOI deletion without a link' do
          subject.run
          expect(user.mailbox.inbox.first.subject).to eq('DOI deleted')
          expect(user.mailbox.inbox.first.messages.first.body).to include(
            "DOI 'doi1' was removed for a deleted object: 'badid'")
        end
      end
    end
  end

  describe '#deactivate_or_remove_doi' do
    let(:user) { create(:user) }

    before do
      expect(subject).to receive(:deactivate_or_remove_doi).and_call_original
    end

    describe 'non-Galter DOI' do
      let(:identifier) { double(
        'ezid-id', id: 'doi', shadowedby: 'ark', status: 'reserved'
      ) }

      before do
        expect(Ezid::Identifier).to receive(:find).and_raise(Ezid::Error)
      end

      it 'does nothing' do
        expect_any_instance_of(Ezid::Identifier).not_to receive(:delete)
        expect_any_instance_of(Ezid::Identifier).not_to receive(:save)
        expect { subject.deactivate_or_remove_doi }.not_to change {
          subject.status }
      end
    end

    context 'Galter DOI' do
      describe 'DOI with a "reserved" status' do
        let(:identifier) { double('ezid-id', status: 'reserved') }

        before do
          expect(Ezid::Identifier).to receive(:find).and_return(identifier)
        end

        it 'deletes the DOI' do
          expect(identifier).to receive(:delete)
          expect { subject.deactivate_or_remove_doi }.to change {
            subject.status }.to('deleted')
        end
      end

      describe 'DOI with a non-"reserved" status' do
        let(:identifier) { double('ezid-id', status: 'bogus') }

        before do
          expect(Ezid::Identifier).to receive(:find).and_return(identifier)
        end

        it 'deletes the DOI' do
          expect(identifier).to receive(:status=).with('unavailable')
          expect(identifier).to receive(:save)
          expect { subject.deactivate_or_remove_doi }.to change {
            subject.status }.to('deactivated')
        end
      end
    end
  end
end
