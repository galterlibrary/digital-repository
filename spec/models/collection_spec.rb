require 'rails_helper'
RSpec.describe Collection do
  let(:user) { FactoryGirl.create(:user) }
  context '#pagable_members' do
    let(:collection) { Collection.new(id: 'col1', title: 'something') }

    describe 'is pagable' do
      before do
        collection.multi_page = true
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
        collection.multi_page = false
        allow(collection).to receive(:members).and_return([
          GenericFile.new(id: 'gf3'),
          GenericFile.new(id: 'gf1'),
          GenericFile.new(id: 'gf2'),
          GenericFile.new(id: 'gf4')
        ])
      end

      subject { collection.pagable_members }

      it 'returns all pagable members in order' do
        expect(subject.map(&:page_number)).to be_blank
      end
    end
  end

  context '#pagable?' do
    let(:collection) { Collection.new(id: 'col1', title: 'something') }

    describe 'is pagable' do
      before do
        collection.multi_page = true
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
          GenericFile.new(id: 'gf3', page_number: '11'),
          GenericFile.new(id: 'gf1', page_number: '9'),
          GenericFile.new(id: 'gf2', page_number: '10'),
          GenericFile.new(id: 'gf4')
        ])
      end

      subject { collection.pagable? }

      it { is_expected.to be_falsy }
    end
  end

  context 'custom metadata' do
    describe "abstract" do
      it "has it" do
        expect(subject.abstract).to eq([])
        subject.abstract = ['abc']
        subject.save(validate: false)
        expect(subject.reload.abstract).to be_truthy
      end
    end

    describe "bibliographic_citation" do
      it "has it" do
        expect(subject.bibliographic_citation).to eq([])
        subject.bibliographic_citation = ['abc']
        subject.save(validate: false)
        expect(subject.reload.bibliographic_citation).to be_truthy
      end
    end

    describe "subject_name" do
      it "has it" do
        expect(subject.subject_name).to eq([])
        subject.subject_name = ['abc']
        subject.save(validate: false)
        expect(subject.reload.subject_name).to be_truthy
      end
    end

    describe "subject_geographic" do
      it "has it" do
        expect(subject.subject_geographic).to eq([])
        subject.subject_geographic = ['abc']
        subject.save(validate: false)
        expect(subject.reload.subject_geographic).to be_truthy
      end
    end

    describe "lcsh" do
      it "has it" do
        expect(subject.lcsh).to eq([])
        subject.lcsh = ['abc']
        subject.save(validate: false)
        expect(subject.reload.lcsh).to be_truthy
      end
    end

    describe "mesh" do
      it "has it" do
        expect(subject.mesh).to eq([])
        subject.mesh = ['abc']
        subject.save(validate: false)
        expect(subject.reload.mesh).to be_truthy
      end
    end

    describe "digital_origin" do
      it "has it" do
        expect(subject.digital_origin).to eq([])
        subject.digital_origin = ['abc']
        subject.save(validate: false)
        expect(subject.reload.digital_origin).to be_truthy
      end
    end

    describe "page_number" do
      it "has it" do
        expect(subject.page_number).to be_nil
        subject.page_number = 22
        subject.save(validate: false)
        expect(subject.reload.page_number).to eq(22)
      end
    end

    describe "multi_page" do
      it "has it" do
        expect(subject.multi_page).to be_nil
        subject.multi_page = true
        subject.save(validate: false)
        expect(subject.reload.multi_page).to be_truthy
      end
    end
  end

  context 'children-parent relation' do
    let(:collection) { make_collection(user) }
    let(:collection_parent) { make_collection(user) }
    let(:collection_child) { make_collection(user) }
    let(:member1) { make_generic_file(user, { title: ['Member 1'] }) }
    let(:non_member) { make_generic_file(user, { title: ['Non-member'] }) }
    let(:member2) { make_generic_file(user, { title: ['Member 2'] }) }

    it { is_expected.to respond_to(:children) }

    it 'recognizes its own generic files children' do
      member1.parent = collection
      member1.save!
      member2.parent = collection
      member2.save!
      non_member.parent = nil
      non_member.save!
      expect(collection.children).to include(member1)
      expect(collection.children).to include(member2)
      expect(collection.children).not_to include(non_member)
    end

    it 'recognizes its own collection children' do
      collection.parent = collection_parent
      collection.save!
      expect(collection_parent.children.count).to eq(1)
      expect(collection_parent.children).to include(collection)
      expect(collection.children).to be_blank
    end

    it 'cannot have a generic file parent' do
      expect { collection.parent = member1 }.to raise_error(
        ActiveFedora::AssociationTypeMismatch)
    end

    it 'can be a child and parent to mixed type children' do
      collection.parent = collection_parent
      collection.save!
      member1.parent = collection
      member1.save!
      member2.parent = collection
      member2.save!
      collection_child.parent = collection
      collection_child.save!
      expect(collection_child.children.count).to eq(0)
      expect(collection_parent.children.count).to eq(1)
      expect(collection.children.count).to eq(3)
      expect(collection.children).to include(member1)
      expect(collection.children).to include(member2)
      expect(collection.children).to include(collection_child)
    end
  end

  context 'combined file association' do
    let(:collection) { make_collection(user) }
    let(:full_file) { make_generic_file(user, { title: ['Full File 1'] }) }

    it { is_expected.to respond_to(:children) }

    it 'recognizes its own generic files children' do
      collection.combined_file = full_file
      collection.save!
      collection.reload
      expect(collection.combined_file).to eq(full_file)
    end

    it 'cannot have a collection-type combined file' do
      expect { collection.combined_file = make_collection(user) }.to raise_error(
        ActiveFedora::AssociationTypeMismatch)
    end
  end

  context 'visibility' do
    let(:collection) { Collection.new(title: 'something') }
    it 'is open visibility upon create' do
      collection.apply_depositor_metadata(user.username)
      collection.save
      expect(collection.visibility).to eq('open')
    end

    it 'preserves visibility when updated' do
      collection.apply_depositor_metadata(user.username)
      collection.save
      collection.visibility = 'restricted'
      collection.save
      expect(collection.visibility).to eq('restricted')
    end
  end
end
