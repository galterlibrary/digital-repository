require 'rails_helper'
RSpec.describe Collection do
  context '#pagable_members' do
    let(:collection) { Collection.new(id: 'col1', title: 'something') }

    describe 'is pagable' do
      before do
        allow(collection).to receive(:members).and_return([
          GenericFile.new(id: 'gf3', page_number: '11'),
          GenericFile.new(id: 'gf1', page_number: '9'),
          GenericFile.new(id: 'gf2', page_number: '10'),
          GenericFile.new(id: 'gf4')
        ])
      end

      subject { collection.pagable_members }

      it 'returns all pagable members in order' do
        expect(subject.map(&:page_number)).to eq(['9', '10', '11'])
      end
    end

    describe 'is not pagable' do
      before do
        allow(collection).to receive(:members).and_return([
          GenericFile.new(id: 'gf3'),
          GenericFile.new(id: 'gf1'),
          GenericFile.new(id: 'gf2')
        ])
      end

      subject { collection.pagable_members }

      it 'returns all pagable members in order' do
        expect(subject.map(&:page_number)).to eq([])
      end
    end
  end

  context '#pagable?' do
    let(:collection) { Collection.new(id: 'col1', title: 'something') }

    describe 'is pagable' do
      before do
        allow(collection).to receive(:members).and_return([
          GenericFile.new(id: 'gf3', page_number: '11'),
          GenericFile.new(id: 'gf1', page_number: '9'),
          GenericFile.new(id: 'gf2', page_number: '10'),
          GenericFile.new(id: 'gf4')
        ])
      end

      subject { collection.pagable? }

      it { is_expected.to be_truthy }
    end

    describe 'is not pagable' do
      before do
        allow(collection).to receive(:members).and_return([
          GenericFile.new(id: 'gf3'),
          GenericFile.new(id: 'gf1'),
          GenericFile.new(id: 'gf2')
        ])
      end

      subject { collection.pagable? }

      it { is_expected.to be_falsy }
    end
  end
end
