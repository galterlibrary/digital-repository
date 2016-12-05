require 'rails_helper'

feature "Authentication", :type => :feature do
  before do
    visit '/'
    within '#user_utility_lg' do
      click_link 'Login'
    end
  end

  subject { page }

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

    specify do
      expect(page).to have_text('Invalid login or password.')
      expect(page).to have_link('Login')
      expect(page).not_to have_text('Noonoo The First')
    end
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

    specify do
      expect(page).to have_text('Invalid login or password.')
      expect(page).to have_link('Login')
      expect(page).not_to have_text('Noonoo The First')
    end
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
        allow_any_instance_of(Nuldap).to receive(
          :search).and_return([true, {
            'mail' => ['a@b.c'],
            'displayName' => ['Noonoo The First']
          }])
        click_button 'Log in'
      end

      specify do
        expect(page).not_to have_link('Login')
        expect(page).to have_text('Noonoo The First')
        expect(current_path).to eq('/dashboard')
      end
    end

    context 'user is not in local db' do
      before do
        fill_in 'NetID', with: 'noonoo'
        fill_in 'Password', with: 'realdeal'
        click_button 'Log in'
      end

      specify do
        expect(page).not_to have_link('Login')
        expect(page).to have_text('First Last')
        expect(current_path).to eq('/dashboard')
        expect(User.find_by_username('noonoo')).not_to be_nil
      end
    end

    describe 'user attributes LDAP-based populate' do
      before do
        visit '/files/new'
        fill_in 'NetID', with: 'noonoo'
        fill_in 'Password', with: 'realdeal'
      end

      it 'only populates user attributes after authentication' do
        expect_any_instance_of(User).to receive(
          :populate_attributes).once
        click_button 'Log in'
        visit '/dashboard'
      end
    end

    context 'user accessing a secure location' do
      before do
        visit '/files/new'
        fill_in 'NetID', with: 'noonoo'
        fill_in 'Password', with: 'realdeal'
        click_button 'Log in'
      end

      specify do
        expect(current_path).to eq('/files/new')
      end
    end

    context 'hitting login button takes you back to where you were' do
      before do
        visit '/catalog'
        within '#user_utility_lg' do
          click_link 'Login'
        end
        fill_in 'NetID', with: 'noonoo'
        fill_in 'Password', with: 'realdeal'
        click_button 'Log in'
      end

      specify do
        expect(current_path).to eq('/catalog')
      end
    end

  end
end
