require 'rails_helper'
RSpec.describe Collection do
  let(:user) { FactoryGirl.create(:user) }
  context '#pageable_members' do
    let(:collection) {
      Collection.new(id: 'col1', title: 'something', tag: ['tag'])
    }

    describe 'with a Collection member' do
      before do
        collection.multi_page = true
        collection.apply_depositor_metadata(user)
        collection.members = [
          make_generic_file(user, id: 'gf3', page_number: '11'),
          make_generic_file(user, id: 'gf1', page_number: '10'),
          make_generic_file(user, id: 'gf2', page_number: '9'),
          make_generic_file(user, id: 'gf4'),
          make_collection(user, id: 'col2')
        ]
        collection.save
      end

      subject { collection.pageable_members.map{|o| o['id'] } }

      it 'excludes the collection from pageable members' do
        expect(subject).to include('gf1')
        expect(subject).to include('gf2')
        expect(subject).to include('gf3')
        expect(subject).not_to include('gf4')
        expect(subject).not_to include('col1')
      end
    end

    describe 'with a no pageable members' do
      before do
        collection.multi_page = true
        collection.apply_depositor_metadata(user)
        collection.members = [
          make_generic_file(user, id: 'gf3')
        ]
        collection.save
      end

      subject { collection.pageable_members }

      it { is_expected.to eq([]) }
    end

    describe 'with a no members' do
      before do
        collection.multi_page = true
        collection.apply_depositor_metadata(user)
        collection.save
      end

      subject { collection.pageable_members }

      it { is_expected.to eq([]) }
    end
  end

  context '#pageable?' do
    let(:collection) { Collection.new(id: 'col1', title: 'something') }

    describe 'is pageable' do
      before do
        collection.multi_page = true
        allow(collection).to receive(:pageable_members).and_return([
          GenericFile.new(id: 'gf3', page_number: '11'),
          GenericFile.new(id: 'gf1', page_number: '9'),
          GenericFile.new(id: 'gf2', page_number: '10'),
          GenericFile.new(id: 'gf4')
        ])
      end

      subject { collection.pageable? }

      it { is_expected.to be_truthy }
    end

    describe 'non-multi-page collection is not pageable' do
      before do
        allow(collection).to receive(:pageable_members).and_return([
          GenericFile.new(id: 'gf3', page_number: '11'),
          GenericFile.new(id: 'gf1', page_number: '9'),
          GenericFile.new(id: 'gf2', page_number: '10'),
          GenericFile.new(id: 'gf4')
        ])
      end

      subject { collection.pageable? }

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

  context 'validations' do
    it 'checks that title is not blank' do
      col = Collection.new(tag: ['abc'])
      col.apply_depositor_metadata(user.username)
      expect{ col.save! }.to raise_error{ ActiveFedora::RecordInvalid }
    end

    it 'checks that tag is not blank' do
      col = Collection.new(title: 'abc')
      col.apply_depositor_metadata(user.username)
      expect{ col.save! }.to raise_error{ ActiveFedora::RecordInvalid }
    end

    it 'saves a record with tag and title filled in' do
      col = Collection.new(title: 'abc', tag: ['bcd'])
      col.apply_depositor_metadata(user.username)
      expect(col.save!).to be_truthy
    end
  end

  context 'visibility' do
    let(:collection) { Collection.new(title: 'something', tag: ['tag']) }
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

  describe 'date_uploaded' do
    it 'sets the date_uploaded upon create' do
      collection = Collection.new(id: 'col1', title: 'something', tag: ['tag'])
      collection.apply_depositor_metadata(user.username)
      collection.save!
      expect(collection.date_uploaded).to be_present
      expect(collection.date_uploaded).to be_a_kind_of(Date)
    end
  end

  describe 'date_modified' do
    it 'sets the date_modified upon save' do
      collection = Collection.new(id: 'col1', title: 'something', tag: ['tag'])
      collection.apply_depositor_metadata(user.username)
      collection.save!
      expect(collection.date_modified).to be_present
      expect(collection.date_modified).to be_a_kind_of(Date)
    end
  end

  describe '::bytes' do
    let(:collection) {
      Collection.new(id: 'col1', title: 'something', tag: ['tag'])
    }
    subject { collection.bytes }
    context 'with no items' do
      it 'gets zero without querying solr' do
        expect(ActiveFedora::SolrService).not_to receive(:query)
        is_expected.to eq 0
      end
    end

    context 'with three 33 byte files' do
      let(:bitstream) { double('content', size: '33') }
      let(:file) { mock_model GenericFile, content: bitstream }
      let(:page) { mock_model Page, content: bitstream }
      let(:documents) do
        [{ 'id' => 'file-1', 'file_size_is' => 33 },
         { 'id' => 'file-2', 'file_size_is' => 33 },
         { 'id' => 'file-3', 'file_size_is' => 33 }]
      end
      let(:query) {
        '_query_:"{!raw f=has_model_ssim}Page" OR _query_:"{!raw f=has_model_ssim}GenericFile"'
      }
      let(:args) do
        { fq: '{!join from=hasCollectionMember_ssim to=id}id:col1',
          fl: 'id, file_size_is',
          rows: 3 }
      end

      before do
        allow(collection).to receive(:members).and_return([file, file, page])
        allow(ActiveFedora::SolrService).to receive(:query).with(
          query, args).and_return(documents)
      end

      context 'when saved' do
        before do
          allow(collection).to receive(:new_record?).and_return(false)
        end
        it { is_expected.to eq 99 }
      end

      context 'when not saved' do
        it 'raises an error' do
          expect { subject }.to raise_error 'Collection must be saved to query for bytes'
        end
      end
    end

    context 'with real Page and GenericFile objects' do
      let(:collection) { make_collection(user, member_ids: [page.id, file.id]) }
      let(:bitstream) { double('content', size: '33') }
      let(:file) { make_generic_file(user) }
      let(:page) { make_page(user) }

      before do
        allow(file).to receive(:content).and_return(bitstream)
        allow(page).to receive(:content).and_return(bitstream)
        file.update_index
        page.update_index
      end

      context 'when saved' do
        it { is_expected.to eq 66 }
      end
    end
  end
end
