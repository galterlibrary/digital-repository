require 'rails_helper'

feature "Authentication", :type => :feature do
  before do
    visit '/'
    click_link 'Login'
  end

  describe 'user is not in LDAP' do
    let!(:bad_user) {
      create(:user, username: 'noonoo', display_name: 'Noonoo The First')
    }

    before do
      #TODO test with real LDAP
      allow_any_instance_of(User).to receive(
        :valid_ldap_authentication?).and_return(false)
      fill_in 'NetID', with: 'noonoo'
      fill_in 'Password', with: 'bogus'
      click_button 'Log in'
    end
    subject { page }

    it { is_expected.to have_text('Invalid login or password.') }
    it { is_expected.to have_link('Login') }
    it { is_expected.not_to have_text('Noonoo The First') }
  end

  describe 'bad password' do
    let!(:bad_user) {
      create(:user, username: 'noonoo', display_name: 'Noonoo The First')
    }

    before do
      #TODO test with real LDAP
      allow_any_instance_of(User).to receive(
        :valid_ldap_authentication?).and_return(false)
      fill_in 'NetID', with: 'noonoo'
      fill_in 'Password', with: 'bogus'
      click_button 'Log in'
    end
    subject { page }

    it { is_expected.to have_text('Invalid login or password.') }
    it { is_expected.to have_link('Login') }
    it { is_expected.not_to have_text('Noonoo The First') }
  end

  describe 'user is in LDAP' do
    before do
      #TODO test with real LDAP
      allow_any_instance_of(User).to receive(
        :valid_ldap_authentication?).and_return(true)
      allow_any_instance_of(User).to receive(:add_to_nuldap_groups)
    end

    context 'user is in local db' do
      let!(:user) {
        create(:user, username: 'noonoo', display_name: 'Noonoo The First')
      }

      before do
        fill_in 'NetID', with: 'noonoo'
        fill_in 'Password', with: 'realdeal'
        click_button 'Log in'
      end
      subject { page }

      it { is_expected.not_to have_link('Login') }
      it { is_expected.to have_text('Noonoo The First') }

      it 'redirect to the dashboard' do
        expect(current_path).to eq('/dashboard')
      end
    end

    context 'user is not in local db' do
      before do
        fill_in 'NetID', with: 'noonoo'
        fill_in 'Password', with: 'realdeal'
        click_button 'Log in'
      end
      subject { page }

      it { is_expected.not_to have_link('Login') }
      it { is_expected.to have_text('noonoo') }

      it 'redirect to the dashboard' do
        expect(current_path).to eq('/dashboard')
      end

      it 'creates the user in local db' do
        expect(User.find_by_username('noonoo')).not_to be_nil
      end
    end
  end
end
