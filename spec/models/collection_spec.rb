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
        allow(bitstream).to receive(:has_content?).and_return(false)
        file.update_index
        page.update_index
      end

      context 'when saved' do
        it { is_expected.to eq 66 }
      end
    end
  end

  describe '#to_solr' do
    it 'generates label' do
      subject.title = 'asdf'
      expect(subject.to_solr['label_si']).to eq('asdf')
    end

    it 'generates rights_sim for Rights Statement' do
      subject.rights = ['http://creativecommons.org/publicdomain/mark/1.0/']
      expect(subject.to_solr['rights_sim']).to eq(['Public Domain Mark 1.0'])
    end
  end

  describe '#add_institutional_admin_permissions' do
    let(:inst_user) { create(:user, username: 'institutional-abc') }
    let(:institutional_parent) { make_collection(
      inst_user, institutional_collection: true, id: 'inst_col') }
    let(:non_institutional_parent) { make_collection(
      user, institutional_collection: false, id: 'non_inst_col') }
    let(:child_collection) { make_collection(
      user, institutional_collection: false, id: 'child_col') }

    context 'parent is not an institutional_collection' do
      before do
        non_institutional_parent.permissions.create(
          name: 'Inst-Admin', type: 'group', access: 'edit')
        non_institutional_parent.update_index
        child_collection.add_institutional_admin_permissions(
          non_institutional_parent.id)
      end

      it 'does not change the child permissions' do
        expect(
          non_institutional_parent.reload.permissions.map(&:agent_name)
        ).to include('Inst-Admin')
        expect(child_collection.reload.permissions.count).to eq(2)
        expect(child_collection.permissions.map(&:agent_name)).not_to include(
          'Inst-Admin')
      end
    end

    context 'parent collection does not exist' do
      it 'throws an exception' do
        expect {
          child_collection.add_institutional_admin_permissions('bad')
        }.to raise_exception(Blacklight::Exceptions::InvalidSolrID)
      end
    end

    context 'parent is an institutional_collection' do
      before do
        institutional_parent.permissions.create(
          name: 'Inst-Admin', type: 'group', access: 'edit')
        institutional_parent.permissions.create(
          name: 'Inst2-Admin', type: 'group', access: 'edit')
        institutional_parent.update_index
      end

      it 'changes the child permissions' do
        child_collection.add_institutional_admin_permissions(
          institutional_parent.id)
        expect(
          child_collection.permissions.map(&:agent_name)
        ).to match_array(['public', 'Inst-Admin', 'Inst2-Admin', user.username])
      end

      describe 'adding collections with members' do
        let(:child_collection_l2) { make_collection(
          user, institutional_collection: false, id: 'child_col1_lv2') }
        let(:child_collection2_l2) { make_collection(
          user, institutional_collection: false, id: 'child_col2_lv2') }
        let(:child_file_l3) { make_generic_file(user, id: 'child_gf_lv3',
          visibility: 'open') }
        let(:child_collection_l3) { make_collection(
          user, institutional_collection: false, id: 'child_col_lv3') }

        before do
          child_collection.members = [child_collection_l2,
                                      child_collection2_l2]
          child_collection.save!
          child_collection_l2.members = [child_collection_l3]
          child_collection_l2.save!
          child_collection2_l2.members = [child_file_l3]
          child_collection2_l2.save!
        end

        it 'changes permissions of all the nodes' do
          child_collection.add_institutional_admin_permissions(
            institutional_parent.id)
          expect(
            child_collection.permissions.map(&:agent_name)
          ).to match_array(['public', 'Inst-Admin', 'Inst2-Admin', user.username])
          expect(child_collection.depositor).to eq(user.username)
          expect(child_collection.institutional_collection).to be_falsy

          expect(
            child_collection_l2.permissions.map(&:agent_name)
          ).to match_array(['public', user.username])

          expect(
            child_collection2_l2.permissions.map(&:agent_name)
          ).to match_array(['public', user.username])

          expect(
            child_collection_l3.permissions.map(&:agent_name)
          ).to match_array(['public', user.username])

          expect(
            child_file_l3.permissions.map(&:agent_name)
          ).to match_array(['public', user.username])
        end
      end

      describe 'Special meaning of institutional -Admin group' do
        before do
          institutional_parent.permissions.create(
            name: 'Inst-User', type: 'group', access: 'edit')
        end

        it 'ignores the non-admin permissions' do
          child_collection.add_institutional_admin_permissions(
            institutional_parent.id)
          expect(
            child_collection.permissions.map(&:agent_name)
          ).to match_array(['public', 'Inst-Admin', 'Inst2-Admin', user.username])
        end
      end
    end
  end

  describe '#convert_to_institutional' do
    let(:unrelated_col) { make_collection(user, title: 'Unrelated') }
    let(:user_col2) { make_collection(user, title: 'User2') }
    let(:user_col) { make_collection(
      user, title: 'User1', member_ids: user_col2.id) }
    let(:user_gf) { make_generic_file(user, title: ['Gf1']) }
    let(:user_parent) { make_collection(
      user, title: 'Parent of the tree', member_ids: [user_col.id, user_gf.id]) }

      subject { user_parent }

    it 'converts the whole structure' do
      subject.convert_to_institutional('institutional-abc')

      # Sets the institutional depositor
      expect(user_parent.reload.depositor).to eq('institutional-abc-root')
      expect(user_col.reload.depositor).to eq('institutional-abc')
      expect(user_col2.reload.depositor).to eq('institutional-abc')
      # Leaves the file depositor unchanged
      expect(user_gf.reload.depositor).to eq(user.username)
      # Leaves the collection not in the structure unchanged
      expect(unrelated_col.reload.depositor).to eq(user.username)

      expect(User.find_by(username: 'institutional-abc-root')).to be_a(User)
      expect(User.find_by(username: 'institutional-abc')).to be_a(User)

      expect(user_parent.institutional_collection).to be_truthy
      expect(user_col.institutional_collection).to be_truthy
      expect(user_col2.institutional_collection).to be_truthy
      expect(unrelated_col.institutional_collection).to be_falsy

      # Creates and propagates a default root admin group
      expect(user_parent.permissions.map(&:agent_name)).to include(
        'Parent-of-the-tree-Admin')
      expect(user_col.permissions.map(&:agent_name)).to include(
        'Parent-of-the-tree-Admin')
      expect(user_col2.permissions.map(&:agent_name)).to include(
        'Parent-of-the-tree-Admin')
      expect(user_gf.permissions.map(&:agent_name)).to include(
        'Parent-of-the-tree-Admin')
      expect(unrelated_col.permissions.map(&:agent_name)).not_to include(
        'Parent-of-the-tree-Admin')
    end

    context 'bad depositor passed' do
      it 'throws an error' do
        expect{
          subject.convert_to_institutional('abc')
        }.to raise_error(RuntimeError)
      end
    end

    context 'depositor containing root passed' do
      it 'sets the depositor properly' do
        subject.convert_to_institutional('institutional-abc-root')

        # Sets the institutional depositor
        expect(user_parent.reload.depositor).to eq('institutional-abc-root')
        expect(user_col.reload.depositor).to eq('institutional-abc')
        expect(user_col2.reload.depositor).to eq('institutional-abc')
        expect(user_gf.reload.depositor).to eq(user.username)
        expect(unrelated_col.reload.depositor).to eq(user.username)
      end
    end

    context 'depositor containing root passed to a non-root node' do
      subject { user_col }

      describe 'no parent_id passed' do
        it 'sets the depositor as root' do
          subject.convert_to_institutional('institutional-abc-root')

          # Sets the institutional depositor
          expect(user_col.reload.depositor).to eq('institutional-abc-root')
          expect(user_col2.reload.depositor).to eq('institutional-abc')
          expect(user_gf.reload.depositor).to eq(user.username)
          expect(unrelated_col.reload.depositor).to eq(user.username)
          expect(user_parent.reload.depositor).to eq(user.username)
        end
      end

      describe 'parent_id passed' do
        it 'sets the depositor as root' do
          subject.convert_to_institutional(
            'institutional-abc-root', user_parent.id)

          # Sets the institutional depositor
          expect(user_col.reload.depositor).to eq('institutional-abc')
          expect(user_col2.reload.depositor).to eq('institutional-abc')
          expect(user_gf.reload.depositor).to eq(user.username)
          expect(unrelated_col.reload.depositor).to eq(user.username)
          expect(user_parent.reload.depositor).to eq(user.username)
        end
      end
    end

    context 'admin group specified' do
      it 'sets the custom group instead of default' do
        subject.convert_to_institutional('institutional-abc', nil, 'Cool-Admin')
        # Creates and propagates a default root admin group
        expect(user_parent.reload.permissions.map(&:agent_name)).to include(
          'Cool-Admin')
        expect(user_col.reload.permissions.map(&:agent_name)).to include(
          'Cool-Admin')
        expect(user_col2.reload.permissions.map(&:agent_name)).to include(
          'Cool-Admin')
        expect(user_gf.reload.permissions.map(&:agent_name)).to include(
          'Cool-Admin')
        expect(unrelated_col.reload.permissions.map(&:agent_name)).not_to include(
          'Cool-Admin')
      end
    end

    context 'non-admin group specified' do
      it 'sets the custom group on the root but not children' do
        subject.convert_to_institutional('institutional-abc', nil, 'Cool-Cats')
        # Creates and propagates a default root admin group
        expect(user_parent.reload.permissions.map(&:agent_name)).to include(
          'Cool-Cats')
        expect(user_col.reload.permissions.map(&:agent_name)).not_to include(
          'Cool-Cats')
        expect(user_col2.reload.permissions.map(&:agent_name)).not_to include(
          'Cool-Cats')
        expect(user_gf.reload.permissions.map(&:agent_name)).not_to include(
          'Cool-Cats')
        expect(unrelated_col.reload.permissions.map(&:agent_name)).not_to include(
          'Cool-Cats')
      end
    end

    context 'no admin group passed for a root with a long title' do
      before do
        user_parent.title = 'Very Very Very Very Very Very Very Long Title'
        user_parent.save
      end

      it 'uses a shortened title for the group name' do
        subject.convert_to_institutional('institutional-abc')
        # Creates and propagates a default root admin group
        expect(user_parent.reload.permissions.map(&:agent_name)).to include(
          'Very-Very-Very-Very-Very-Very-Very-Long-T-Admin')
        expect(user_col.reload.permissions.map(&:agent_name)).to include(
          'Very-Very-Very-Very-Very-Very-Very-Long-T-Admin')
        expect(user_col2.reload.permissions.map(&:agent_name)).to include(
          'Very-Very-Very-Very-Very-Very-Very-Long-T-Admin')
        expect(user_gf.reload.permissions.map(&:agent_name)).to include(
          'Very-Very-Very-Very-Very-Very-Very-Long-T-Admin')
        expect(unrelated_col.reload.permissions.map(&:agent_name)).not_to include(
          'Very-Very-Very-Very-Very-Very-Very-Long-T-Admin')
      end
    end

    context 'no admin group passed for a root with a non-ascii title' do
      before do
        user_parent.title = 'Księga grzotów i błyskawic'
        user_parent.save
      end

      it 'uses a shortened title for the group name' do
        subject.convert_to_institutional('institutional-abc')
        # Creates and propagates a default root admin group
        expect(user_parent.reload.permissions.map(&:agent_name)).to include(
          'Ksiga-grzotw-i-byskawic-Admin')
        expect(user_col.reload.permissions.map(&:agent_name)).to include(
          'Ksiga-grzotw-i-byskawic-Admin')
        expect(user_col2.reload.permissions.map(&:agent_name)).to include(
          'Ksiga-grzotw-i-byskawic-Admin')
        expect(user_gf.reload.permissions.map(&:agent_name)).to include(
          'Ksiga-grzotw-i-byskawic-Admin')
        expect(unrelated_col.reload.permissions.map(&:agent_name)).not_to include(
          'Ksiga-grzotw-i-byskawic-Admin')
      end
    end
  end

  describe '#normalize_institutional' do
    let(:user_col) { make_collection(user, title: 'User1') }
    let(:user_gf) { make_generic_file(user, title: ['Gf1']) }
    let(:user_parent) { make_collection(
      user, title: 'User1', member_ids: [user_col.id, user_gf.id]) }

    context 'structure has no institutional collections' do
      subject { user_parent }

      it 'does nothing' do
        subject.normalize_institutional('abc', 'ABC-Admin')
        expect(user_parent).not_to receive(:adjust_institutional_permissions)
        expect(user_col).not_to receive(:adjust_institutional_permissions)
        expect(user_gf).not_to receive(:adjust_institutional_permissions)
      end
    end

    context 'structure has institutional collections' do
      let(:inst_col2_1) { make_collection(
        user, title: 'IColl2.1', institutional_collection: true) }
      let(:inst_col1_1) { make_collection(
        user, title: 'IColl1.1', member_ids: [inst_col2_1.id],
        institutional_collection: true
      ) }
      let(:inst_col1_2) { make_collection(
        user, title: 'IColl1.2', institutional_collection: true) }
      let(:inst_root) { make_collection(
        user, title: 'IRoot1', institutional_collection: true,
        member_ids: [inst_col1_1.id, inst_col1_2.id, user_parent.id]
      ) }

      subject { inst_root }

      describe 'institutional user does not exist, no permissions' do
        specify do
          subject.normalize_institutional('institutional-abc')

          # Depositor changed for institutional collections
          expect(inst_root.reload.depositor).to eq('institutional-abc-root')
          expect(inst_col1_1.reload.depositor).to eq('institutional-abc')
          expect(inst_col1_2.reload.depositor).to eq('institutional-abc')
          expect(inst_col2_1.reload.depositor).to eq('institutional-abc')
          expect(user_parent.reload.depositor).to eq(user.username)
          expect(user_col.reload.depositor).to eq(user.username)
          expect(user_gf.reload.depositor).to eq(user.username)

          # Doesn't touch the institutional status
          expect(inst_root.institutional_collection).to be_truthy
          expect(inst_col1_1.institutional_collection).to be_truthy
          expect(inst_col1_2.institutional_collection).to be_truthy
          expect(inst_col2_1.institutional_collection).to be_truthy
          expect(user_parent.institutional_collection).to be_falsy
          expect(user_col.institutional_collection).to be_falsy

          expect(User.find_by(username: 'institutional-abc-root')).to be_a(User)
          expect(User.find_by(username: 'institutional-abc')).to be_a(User)
        end
      end

      describe 'institutional user exist, no permissions' do
        let!(:inst_user_root) { create(
          :user, username: 'institutional-abc-root') }
        let!(:inst_user) { create(:user, username: 'institutional-abc') }
        specify do
          expect(User).not_to receive(:create!)
          subject.normalize_institutional('institutional-abc')

          # Depositor changed for institutional collections
          expect(inst_root.reload.depositor).to eq('institutional-abc-root')
          expect(inst_col1_1.reload.depositor).to eq('institutional-abc')
          expect(inst_col1_2.reload.depositor).to eq('institutional-abc')
          expect(inst_col2_1.reload.depositor).to eq('institutional-abc')
          expect(user_parent.reload.depositor).to eq(user.username)
          expect(user_col.reload.depositor).to eq(user.username)
          expect(user_gf.reload.depositor).to eq(user.username)

          # Doesn't touch the institutional status
          expect(inst_root.institutional_collection).to be_truthy
          expect(inst_col1_1.institutional_collection).to be_truthy
          expect(inst_col1_2.institutional_collection).to be_truthy
          expect(inst_col2_1.institutional_collection).to be_truthy
          expect(user_parent.institutional_collection).to be_falsy
          expect(user_col.institutional_collection).to be_falsy
        end
      end

      describe 'permission changes' do
        let(:user_gf2) { make_generic_file(user) }
        before do
          inst_col1_2.members << user_gf2
          inst_col1_2.save!
          inst_col1_1.permissions.create(
            name: 'Col11-Admin', type: 'group', access: 'edit')
          inst_col1_1.update_index
        end

        specify do
          subject.normalize_institutional('institutional-abc', 'ABC-Admin')

          # Sanity check
          # Depositor changed for institutional collections
          expect(inst_root.reload.depositor).to eq('institutional-abc-root')
          expect(inst_col1_1.reload.depositor).to eq('institutional-abc')
          expect(inst_col1_2.reload.depositor).to eq('institutional-abc')
          expect(inst_col2_1.reload.depositor).to eq('institutional-abc')
          expect(user_parent.reload.depositor).to eq(user.username)
          expect(user_col.reload.depositor).to eq(user.username)
          expect(user_gf.reload.depositor).to eq(user.username)

          # Doesn't touch the institutional status
          expect(inst_root.institutional_collection).to be_truthy
          expect(inst_col1_1.institutional_collection).to be_truthy
          expect(inst_col1_2.institutional_collection).to be_truthy
          expect(inst_col2_1.institutional_collection).to be_truthy
          expect(user_parent.institutional_collection).to be_falsy
          expect(user_col.institutional_collection).to be_falsy

          # Adds ABC-Admin group permissions to all institutional and first
          # child collections and files and propagates institutional Admin
          # permissions
          expect(inst_root.permissions.map(&:agent_name)).to include('ABC-Admin')
          expect(inst_col1_1.permissions.map(&:agent_name)).to include('ABC-Admin')
          expect(inst_col1_2.permissions.map(&:agent_name)).to include('ABC-Admin')
          expect(inst_col2_1.permissions.map(&:agent_name)).to include('ABC-Admin')
          expect(inst_col2_1.permissions.map(&:agent_name)).to include('Col11-Admin')
          expect(user_gf2.reload.permissions.map(&:agent_name)).to include('ABC-Admin')
          expect(user_parent.permissions.map(&:agent_name)).to include('ABC-Admin')
          expect(user_col.permissions.map(&:agent_name)).not_to include('ABC-Admin')
          expect(user_gf.reload.permissions.map(&:agent_name)).not_to include('ABC-Admin')
        end
      end
    end
  end

  describe '#remove_institutional_admin_permissions' do
    context 'parent is not an institutional_collection' do
      let(:non_institutional_parent) { make_collection(
        user, institutional_collection: false, id: 'non_inst_col',
        member_ids: [child_collection.id]
      ) }
      let(:child_collection) { make_collection(
        user, institutional_collection: false, id: 'child_col') }

      before do
        non_institutional_parent.permissions.create(
          name: 'Parent-Admin', type: 'group', access: 'edit')
        non_institutional_parent.update_index
        child_collection.permissions.create(
          name: 'Parent-Admin', type: 'group', access: 'edit')
        non_institutional_parent.update_index
        child_collection.remove_institutional_admin_permissions(
          non_institutional_parent.id)
      end

      it 'does not change the child permissions' do
        expect(child_collection.reload.permissions.count).to eq(3)
        expect(
          non_institutional_parent.reload.permissions.map(&:agent_name)
        ).to include('Parent-Admin')
        expect(child_collection.reload.permissions.count).to eq(3)
        expect(
          child_collection.permissions.map(&:agent_name)
        ).to include('Parent-Admin')
      end
    end

    context 'parent collection does not exist' do
      let(:child_collection) { make_collection(
        user, institutional_collection: false, id: 'child_col') }

      it 'throws an exception' do
        expect {
          child_collection.remove_institutional_admin_permissions('bad')
        }.to raise_exception(Blacklight::Exceptions::InvalidSolrID)
      end
    end

    context 'parent is an institutional_collection' do
      let(:bottom_user) { create(:user) }
      let(:bottom_col) { make_collection(bottom_user) }
      let(:child_collection) { make_collection(
        user, institutional_collection: true, id: 'child_col'
      ) }
      let(:child_collection2) { make_collection(
        user, institutional_collection: true, id: 'child_col2',
        member_ids: [bottom_col.id]
      ) }
      let(:institutional_parent) { make_collection(
        user, institutional_collection: true, id: 'inst_col',
        member_ids: [child_collection.id, child_collection2.id]
      ) }
      let(:root_inst_col) { make_collection(
        user, member_ids: [institutional_parent.id]) }

      before do
        [bottom_col, child_collection, child_collection2, institutional_parent, root_inst_col].each do |c|
          c.permissions.create(name: 'Root-Admin', type: 'group', access: 'edit')
        end
        [bottom_col, child_collection, child_collection2, institutional_parent].each do |c|
          c.permissions.create(name: 'Parent-Admin', type: 'group', access: 'edit')
        end
        [bottom_col, child_collection].each do |c|
          c.permissions.create(name: 'Child-Admin', type: 'group', access: 'edit')
        end
        [bottom_col, child_collection2].each do |c|
          c.permissions.create(name: 'Child2-Admin', type: 'group', access: 'edit')
        end
        bottom_col.permissions.create(name: 'Bottom-Admin', type: 'group', access: 'edit')

        [bottom_col, child_collection, child_collection2, institutional_parent, root_inst_col].each do |c|
          c.update_index
        end

        expect(
          bottom_col.permissions.map(&:agent_name)
        ).to match_array(
          ['public', bottom_user.username, 'Root-Admin', 'Parent-Admin',
           'Child-Admin', 'Child2-Admin', 'Bottom-Admin']
        )
      end

      it 'changes the child permissions' do
        bottom_col.remove_institutional_admin_permissions(
          child_collection.id)
        expect(
          bottom_col.reload.permissions.map(&:agent_name)
        ).to match_array(
          ['public', bottom_user.username, 'Root-Admin', 'Parent-Admin',
           'Child2-Admin', 'Bottom-Admin']
        )
      end

      describe 'Special meaning of institutional -Admin group' do
        before do
          institutional_parent.members = [child_collection2]
          institutional_parent.permissions.create(
            name: 'Inst-User', type: 'group', access: 'edit')
          institutional_parent.save
          child_collection.permissions.create(
            name: 'Inst-User', type: 'group', access: 'edit')
          child_collection.update_index
          expect(
            child_collection.reload.permissions.map(&:agent_name)
          ).to match_array(
            ['public', user.username, 'Root-Admin', 'Parent-Admin',
            'Child-Admin', 'Inst-User']
          )
        end

        it 'ignores the non-admin permissions' do
          child_collection.remove_institutional_admin_permissions(
            institutional_parent.id)
          expect(
            child_collection.reload.permissions.map(&:agent_name)
          ).to match_array(
            ['public', user.username,'Child-Admin', 'Inst-User']
          )
        end
      end
    end
  end

  describe 'invalid characters' do
    it 'can save a file with UTF control characters in the metadata' do
      subject.title = "Northwestern University, \vChicago"
      subject.tag = ['abc', "\vChicago"]
      subject.apply_depositor_metadata('nope')
      expect(subject.save!).to be_truthy
      expect(subject.title).to eq("Northwestern University, Chicago")
      expect(subject.tag).to include('abc')
      expect(subject.tag).to include('Chicago')
    end
  end
end
