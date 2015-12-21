require 'rails_helper'

describe MintDoiJob do
  let(:user) { create(:user, username: 'u1') }
  let(:batch_user) { create(:user, username: 'batch') }
  let(:gf1) { make_generic_file(user, id: 'gf1') }

  subject { described_class.new(gf1.id, user.username) }

  it 'runs the job' do
    expect(subject.object).to receive(:check_doi_presence)
    subject.run
  end

  context 'nothing returned from check_doi_presence' do
    before do
      allow(subject.object).to receive(:check_doi_presence).and_return(nil)
    end

    it 'does not notify the user of doi action' do
      expect(User).not_to receive(:batchuser)
      subject.run
    end
  end

  context 'status returned from check_doi_presence' do
    before { expect(User).to receive(:batchuser).and_return(batch_user) }

    describe 'when doi was generated' do
      before do
        expect(subject.object).to receive(
          :check_doi_presence).and_return('generated')
      end

      it 'notifies the user of file generation' do
        subject.run
        expect(user.mailbox.inbox.first.subject).to eq('DOI generated')
        expect(user.mailbox.inbox.first.messages.first.body).to include(
          "DOI was generated for <a href='/files/gf1'>")
      end
    end

    describe 'when doi was generated for non-public file' do
      before do
        expect(subject.object).to receive(
          :check_doi_presence).and_return('generated_reserved')
      end

      it 'notifies the user of file generation' do
        subject.run
        expect(user.mailbox.inbox.first.subject).to eq('DOI generated')
        expect(user.mailbox.inbox.first.messages.first.body).to match(
          /DOI was generated for <a href='.*gf1'>.*DOI is inactive/)
      end
    end

    describe 'when doi metadata was updated' do
      before do
        expect(subject.object).to receive(
          :check_doi_presence).and_return('updated')
      end

      it 'notifies the user of DOI metadata update' do
        subject.run
        expect(user.mailbox.inbox.first.subject).to eq('DOI metadata updated')
        expect(user.mailbox.inbox.first.messages.first.body).to include(
          "DOI metadata was updated for <a href='/files/gf1'>")
      end
    end

    describe 'when doi metadata was updated for file changing to non-public' do
      before do
        expect(subject.object).to receive(
          :check_doi_presence).and_return('updated_unavailable')
      end

      it 'notifies the user of DOI metadata update' do
        subject.run
        expect(user.mailbox.inbox.first.subject).to eq('DOI metadata updated')
        expect(user.mailbox.inbox.first.messages.first.body).to match(
          /DOI metadata was updated for <a href=.*gf1'>.*has been deactivated/)
      end
    end

    describe 'when file is of type Page' do
      before do
        expect(subject.object).to receive(
          :check_doi_presence).and_return('page')
      end

      it 'notifies the user that it is unwilling to generate a DOI' do
        subject.run
        expect(user.mailbox.inbox.first.subject).to eq('DOI not generated')
        expect(user.mailbox.inbox.first.messages.first.body).to match(
          /DOI was not generated for .*gf1.* because the file is a page/)
      end
    end

    describe 'when file is missing the required metadata' do
      before do
        expect(subject.object).to receive(
          :check_doi_presence).and_return('metadata')
      end

      it 'notifies the user that it cannot generate a DOI' do
        subject.run
        expect(user.mailbox.inbox.first.subject).to eq('DOI not generated')
        expect(user.mailbox.inbox.first.messages.first.body).to match(
          /DOI was not generated for .*gf1.* because the file is missing/)
      end
    end
  end
end
