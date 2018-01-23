require 'rails_helper'

feature 'Admin', :type => :feature do
  subject { page }

  context 'admin user' do
    let(:user) { FactoryGirl.create(:admin_user) }
    let(:non_admin) { FactoryGirl.create(:user) }

    before do
      Role.create!(name: 'admin')
      user.add_role('admin')
      login_as(user)
    end

    specify do
      visit '/'
      expect(page).to have_link('administration', href: '/roles')
      visit '/roles'
      expect(page).to have_link('Manage Resque Jobs')
      expect(page).to have_link('Statistics')
      expect(page).to have_link('Create a new user')
      expect(page).to have_link('Create a new role')
      expect(page).to have_link('admin')
    end

    describe 'creating a user' do
      before { visit '/users/new' }

      context 'with a valid netid' do
        let(:new_user) { FactoryGirl.build(:user, username: 'someid') }

        before do
          expect(User).to receive(:find_or_initialize_by).
                          with(username: 'someid').
                          and_return(new_user)
          allow(new_user).to receive(:persisted?).and_return(false)
          expect(new_user).to receive(:populate_attributes).
                              and_return(new_user.save)
        end

        it 'creates the user' do
          fill_in 'NetID (Username):', with: 'someid'
          click_button 'Create'
          expect(current_path).to eq('/users/someid')
        end
      end

      context 'with an invalid netid' do
        let(:new_user) { FactoryGirl.build(:user, username: 'someid') }

        before do
          expect(User).to receive(:find_or_initialize_by).
                          with(username: 'someid').
                          and_return(new_user)
          allow(new_user).to receive(:persisted?).and_return(false)
          expect(new_user).to receive(:populate_attributes).
                              and_raise(StandardError)
        end

        it 'returns an error' do
          fill_in 'NetID (Username):', with: 'someid'
          click_button 'Create'
          expect(current_path).to eq('/users/new')
          expect(page).to have_text(
            "Couldn't create user, username doesn't exist in LDAP?")
        end
      end

      context 'when something goes wrong saving' do
        let(:new_user) { FactoryGirl.build(:user, username: 'someid') }

        before do
          expect(User).to receive(:find_or_initialize_by).
                          with(username: 'someid').
                          and_return(new_user)
          allow(new_user).to receive(:persisted?).and_return(false)
          expect(new_user).to receive(:populate_attributes).
                              and_raise(ActiveRecord::RecordNotUnique.new(''))
        end

        it 'returns an error' do
          fill_in 'NetID (Username):', with: 'someid'
          click_button 'Create'
          expect(current_path).to eq('/users/new')
          expect(page).to have_text("Couldn't create user:")
        end
      end

      context 'existing user' do
        let(:new_user) { FactoryGirl.create(:user, username: 'someid') }

        before do
          expect(User).to receive(:find_or_initialize_by).
                          with(username: 'someid').
                          and_return(new_user)
          expect(new_user).not_to receive(:populate_attributes)
        end

        it 'returns an error' do
          fill_in 'NetID (Username):', with: 'someid'
          click_button 'Create'
          expect(current_path).to eq('/users/new')
          expect(page).to have_text('User someid already exists')
        end
      end
    end
    
    describe 'user role management' do
      it 'adds/removes user from admin roles' do
        visit '/roles'
        click_link 'admin'
        
        expect(page).to_not have_text(non_admin.username)
        
        fill_in 'User', with: non_admin.username
        click_button 'Add'
        
        expect(page).to have_text(non_admin.username)
        
        within("##{non_admin.username}") {
          click_button "Remove User"
        }
        
        expect(page).to_not have_text(non_admin.username)
      end
    end
  end

  context 'non-admin user' do
    let(:user) { FactoryGirl.create(:user) }

    before do
      login_as(user)
    end

    specify do
      visit '/'
      expect(page).not_to have_link('administration', href: '/roles')
      visit '/users/new'
      expect(current_path).to eq(sufia.profile_path(user.to_param))
      expect(page).to have_text('Permission denied: cannot access')
    end
  end

  context 'anonymous user' do
    specify do
      visit '/'
      expect(page).not_to have_link('administration', href: '/roles')
      visit '/users/new'
      expect(current_path).to eq('/users/sign_in')
    end
  end
end
