require 'rails_helper'

describe 'Shibboleth Authentication', :type => :feature do
  let(:user) { create(:user, username: 'i-exist') }

  context 'non-production rails environment' do
    describe 'user is logging in' do
      it 'renders ldap authentication form' do
        visit '/users/sign_in'
        expect(current_path).to eq('/users/sign_in')
        expect(page).to have_text('NetID')
        expect(page).to have_link('Log in with SSO (Shibboleth)')
      end
    end

    describe 'user is logging out' do
      it 'redirects to root' do
        login_as(user)
        visit '/users/sign_out'
        expect(current_path).to eq('/')
        expect(page).to have_text('Signed out successfully.')
        expect(page).not_to have_text('You MUST close your browser')
      end
    end
  end

  context 'production rails environment' do
    before do
      ENV['SHIBBOLETH_AUTH'] = 'true'
      OmniAuth.config.test_mode = true
    end

    describe 'user is logging out' do
      before do
        Rails.application.routes.send(:eval_block,
          Proc.new {
            get '/Shibboleth.sso/Logout', to: redirect('/')
          }
        )
      end

      it 'redirects to root' do
        login_as(user)
        visit '/users/sign_out'
        expect(current_path).to eq('/')
        expect(page).to have_text('Signed out successfully.')
        expect(page).to have_text('You MUST close your browser')
      end
    end

    describe 'user is accessing a protected path' do
      before do
        OmniAuth.config.add_mock(
          :shibboleth, { uid: "#{user.username}@northwestern.edu" })
      end

      it 'does not display LDAP authentication alert' do
        visit '/files/new'
        expect(current_path).to eq('/files/new')
        expect(page).not_to have_text('You need to sign in or sign up')
      end
    end

    describe 'user is logging in' do
      describe 'logged in user' do
        before do
          login_as(user)
        end

        it 'logged in user stays logged in' do
          visit '/users/sign_in'
          expect(current_path).to eq('/dashboard')
          expect(page).to have_text('First Last')
        end
      end

      describe 'existing northwestern user' do
        before do
          OmniAuth.config.add_mock(
            :shibboleth, { uid: "#{user.username}@northwestern.edu" })
        end

        it 'authenticates user' do
          visit '/users/sign_in'
          expect(current_path).to eq('/dashboard')
          expect(page).to have_text('First Last')
        end
      end

      describe 'user without a domain in uid' do
        before do
          OmniAuth.config.add_mock(
            :shibboleth, { uid: "#{user.username}" })
        end

        it 'assumes a northwestern user and authenticates' do
          visit '/users/sign_in'
          expect(current_path).to eq('/dashboard')
          expect(page).to have_text('First Last')
        end
      end

      describe 'new northwestern user' do
        before do
          OmniAuth.config.add_mock(
            :shibboleth, { uid: "i-dont-exist@northwestern.edu" })
        end

        it 'authenticates user' do
          visit '/users/sign_in'
          expect(current_path).to eq('/dashboard')
          expect(page).to have_text('First Last')
        end
      end

      describe 'non-northwestern user' do
        before do
          OmniAuth.config.add_mock(
            :shibboleth, { uid: "i-dont-exist@uchicago.edu" })
        end

        it 'refuses to athenticate' do
          visit '/users/sign_in'
          expect(current_path).to eq('/')
          expect(page).to have_text('Only Northwestern University affiliates')
        end
      end
    end
  end
end
