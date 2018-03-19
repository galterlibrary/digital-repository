require 'rails_helper'
RSpec.describe User do
  describe 'find_by_login' do
    it 'returns nil if user does not exist' do
      user = create(:user, username: 'noonoo')
      expect(User.find_by_login('bogus')).to be_nil
    end

    it 'returns user matching by username' do
      create(:user)
      user = create(:user, username: 'noonoo')
      expect(User.find_by_login('noonoo')).to eq(user)
    end

    it 'returns user matching by email' do
      create(:user)
      user = create(:user, email: 'noonoo@abc.net')
      expect(User.find_by_login('noonoo@abc.net')).to eq(user)
    end
  end

  describe 'find_for_ldap_authentication' do
    context 'user exists in ldap' do
      before do
        @user = create(:user, username: 'noonoo')
      end

      context 'user exists in local database' do
        subject { User.find_for_ldap_authentication({ login: 'noonoo' }) }

        it { is_expected.to eq(@user) }

        it "desn't create a local user" do
          expect { subject }.not_to change{ User.count }
        end
      end

      context 'user does not exist in local database' do
        before do
          expect_any_instance_of(User).to receive(
            :valid_ldap_authentication?).and_return(true)
          expect_any_instance_of(User).to receive(
            :populate_attributes).and_call_original
          expect_any_instance_of(User).to receive(:nuldap_groups).and_return(
            ['Black Hats', 'DDoSers', 'Script Kiddies']
          )
        end
        subject { User.find_for_ldap_authentication({ login: 'snoosnoo' }) }

        it "creates roles if they don't yet exist and adds user to them" do
          user_roles = subject.groups
          expect(user_roles).to include('Black-Hats')
          expect(user_roles).to include('DDoSers')
          expect(user_roles).to include('Script-Kiddies')
          expect(Role.find_by(name: 'Script-Kiddies')).to be_an_instance_of(Role)
          expect(Role.find_by(name: 'Black-Hats')).to be_an_instance_of(Role)
          expect(Role.find_by(name: 'DDoSers')).to be_an_instance_of(Role)
        end

        it "returns an instace of a User" do
          expect(subject).to be_an_instance_of(User)
          expect(subject.id).not_to be_nil
          expect(subject).not_to eq(@user)
        end

        it "creates a local user even if one with blank email exists" do
          User.create(username: 'badone', email: '')
          expect { subject }.to change{ User.count }.by(1)
        end
      end
    end

    context 'user does not exist in ldap' do
      before do
        @user = create(:user, username: 'noonoo')
      end

      context 'user exists in local database' do
        subject { User.find_for_ldap_authentication({ login: 'noonoo' }) }

        it { is_expected.to eq(@user) }

        it "desn't create a local user" do
          expect { subject }.not_to change{ User.count }
        end
      end

      context 'user does not exist in local database' do
        before do
          expect_any_instance_of(User).to receive(
            :valid_ldap_authentication?).and_return(false)
        end
        subject { User.find_for_ldap_authentication({ login: 'snoosnoo' }) }

        it "returns a new instace of a User" do
          expect(subject).to be_an_instance_of(User)
          expect(subject).to be_a_new_record
        end

        it "desn't create a local user" do
          expect { subject }.not_to change{ User.count }
        end
      end
    end
  end

  describe 'audituser' do
    context 'audituser exists in the local database' do
      let!(:user) { create(:user, username: 'audituser') }
      subject { User.audituser }

      it { is_expected.to eq(user) }
    end

    context 'audituser does not exists in the local database' do
      subject { User.audituser }

      it 'creates an audit user account' do
        expect{
          expect(subject).to be_an_instance_of(User)
          expect(subject.username).to eq('audituser')
        }.to change { User.count }.by(1)
      end
    end
  end

  describe 'audituser_key' do
    subject { User.audituser_key }
    it { is_expected.to eq('audituser') }
  end

  describe 'batchuser' do
    context 'batchuser exists in the local database' do
      let!(:user) { create(:user, username: 'batchuser') }
      subject { User.batchuser }

      it { is_expected.to eq(user) }
    end

    context 'batchuser does not exists in the local database' do
      subject { User.batchuser }

      it 'creates an audit user account' do
        expect{
          expect(subject).to be_an_instance_of(User)
          expect(subject.username).to eq('batchuser')
        }.to change { User.count }.by(1)
      end
    end
  end

  describe 'batchuser_key' do
    subject { User.batchuser_key }
    it { is_expected.to eq('batchuser') }
  end

  describe 'login' do
    let!(:user) { create(:user, username: 'noonoo') }
    context '@login is set' do
      before do
        user.login = 'testa'
      end
      subject { user.login }
      it { is_expected.to eq('testa') }
    end

    context '@login is not set' do
      subject { user.login }
      it { is_expected.to eq('noonoo') }
    end
  end

  describe 'square bracket attribute access' do
    let!(:user) { create(:user, username: 'noonoo') }
    context 'attribute name is ":login"' do
      subject{ user[:login] }

      it { is_expected.to eq('noonoo') }
    end

    context 'attribute name is not ":login"' do
      subject{ user[:username] }

      it { is_expected.to eq('noonoo') }
    end
  end

  describe 'remove_from_group' do
    let(:user) { create(:user) }
    it 'removes user from a group' do
      Role.create(name: 'admin')
      user.add_to_group('admin')
      expect(user.groups).to include('admin')
      user.remove_from_group('admin')
      expect(user.groups).not_to include('admin')
      expect(Role.all.map(&:name)).to include('admin')
    end
  end

  describe 'add_to_group' do
    let(:user) { create(:user) }
    it 'adds user to a group' do
      Role.create(name: 'admin')
      user.add_to_group('admin')
      expect(user.groups).to include('admin')
    end
  end

  describe 'in_group?' do
    let(:user) { create(:user) }
    it 'adds user to a group' do
      Role.create(name: 'admin')
      user.add_to_group('admin')
      expect(user.in_group?('admin')).to be_truthy
    end
  end

  describe '#nuldap_groups' do
    let(:user) { create(:user) }

    it 'returns empty array if no groups' do
      expect_any_instance_of(Nuldap).to receive(:search).and_return([])
      expect(user.nuldap_groups).to be_blank
    end

    it 'returns ldap groups' do
      allow_any_instance_of(Nuldap).to receive(:search).and_return([
        true, { 'ou' => ['People', 'Bad Apples', 'Normal'] }
      ])
      expect(user.nuldap_groups).to include('Bad Apples')
      expect(user.nuldap_groups).to include('Normal')
    end

    it 'does not return "People" group' do
      expect_any_instance_of(Nuldap).to receive(:search).and_return([
        true, { 'ou' => ['People', 'Bad Apples', 'Normal'] }
      ])
      expect(user.nuldap_groups).not_to include('People')
    end
  end

  describe 'groups' do
    let(:user) { create(:user) }
    it 'does not return "registered" by default' do
      pending 'Not sure why we would want that, leving in case I remember'
      expect(user.groups).not_to include('registered')
    end

    it 'returns name event if descriptions present' do
      role_desc = Role.create(name: 'something', description: 'Other stuff')
      user.add_to_group('something')
      expect(user.groups).to include('something')
      expect(user.groups).not_to include('Other stuff')
    end

    it 'returns name if no description' do
      role_desc = Role.create(name: 'something', description: 'Other stuff')
      role_name = Role.create(name: 'no-desc')
      user.add_to_group('something')
      user.add_to_group('no-desc')
      expect(user.groups).to include('something')
      expect(user.groups).not_to include('Other stuff')
      expect(user.groups).to include('no-desc')
    end
  end

  describe '#name' do
    let(:user) { build(
      :user, display_name: 'Display Name', formal_name: 'Name, Formal') }

    subject { user.name }

    it { is_expected.to eq('Display Name') }

    context 'called from file with `actor.rb` in the name' do
      before do
        expect(user).to receive(:caller).and_return(['/blah/actor.rb:321'])
      end

      it { is_expected.to eq('Name, Formal') }
    end
  end

  describe '#find_or_create_via_username' do
    subject { User.find_or_create_via_username('itsame') }

    context 'user does not exists' do
      it 'returns the existing user record' do
        expect_any_instance_of(User).to receive(:add_to_nuldap_groups)
        expect{ subject }.to change { User.count }.by(1)
        expect(subject.username).to eq('itsame')
        expect(subject.display_name).to eq('First Last')
      end
    end

    context 'user exists' do
      let!(:user) { create(:user, username: 'itsame') }

      it 'returns the existing user record' do
        expect_any_instance_of(User).not_to receive(:add_to_nuldap_groups)
        expect_any_instance_of(User).not_to receive(:populate_attributes)
        expect{ subject }.not_to change { User.count }
        expect(subject).to eq(user)
      end
    end
  end

  describe 'populate_attributes' do
    let(:new_user) { User.new(username: 'hello') }
    subject { new_user.populate_attributes }

    context 'orcid id' do
      it 'populates the orcid id' do
        expect(subject).to eq(true)
        expect(new_user.orcid).to eq('https://orcid.org/0000-9999-9999-9999')
      end
    end
  end

  describe 'normalize_orcid' do
    let(:user) { create(:user, username: 'hello') }
    subject { user.update_attributes({ orcid: orcid }) }

    context 'orcid id already normalized' do
      let(:orcid) { 'https://orcid.org/0000-9999-9999-9999' }

      specify do
        expect(subject).to eq(true)
        expect(user.orcid).to eq('https://orcid.org/0000-9999-9999-9999')
      end
    end

    context 'orcid id already normalized with non ssl uri' do
      let(:orcid) { 'http://orcid.org/0000-9999-9999-9999' }

      specify do
        expect(subject).to eq(true)
        expect(user.orcid).to eq('https://orcid.org/0000-9999-9999-9999')
      end
    end

    context 'orcid id is bare' do
      let(:orcid) { '0000-9999-9999-9999' }

      specify do
        expect(subject).to eq(true)
        expect(user.orcid).to eq('https://orcid.org/0000-9999-9999-9999')
      end
    end

    context 'orcid id is bad' do
      let(:orcid) { '9999-9999-9999' }

      specify do
        expect(subject).to eq(false)
        expect(user.reload.orcid).to be_nil
      end
    end

    context 'full orcid id is bad' do
      let(:orcid) { 'https://orcid.org/9999-9999-9999' }

      specify do
        expect(subject).to eq(false)
        expect(user.reload.orcid).to be_nil
      end
    end
  end

  describe '#all_followed_collections' do
    let(:owner) { create(:user) }
    let(:user) { create(:user) }
    let(:ccol) { make_collection(owner, title: 'ccol') }
    let(:acol) { make_collection(owner, title: 'acol') }
    let(:dcol) { make_collection(owner, title: 'dcol') }
    let(:bcol) { make_collection(owner, title: 'bcol') }

    context "when user doesn't follow any collections" do
      specify do
        expect(user.all_followed_collections).to eq([])
      end
    end

    context 'when user follows collections' do
      before do
        ccol.set_follower(user)
        acol.set_follower(user)
        dcol.set_follower(user)
      end

      it 'returns the followed collection sorted by title' do
        expect(user.all_followed_collections).to match_array([
          { title: 'acol', id: acol.id },
          { title: 'ccol', id: ccol.id },
          { title: 'dcol', id: dcol.id }
        ])
      end
    end
  end
end
