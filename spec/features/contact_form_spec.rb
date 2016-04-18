require 'rails_helper'

feature "HomePage", :type => :feature do
  subject { page }
  let(:user) { create(
    :user, display_name: 'Display Name', email: 'test@net.com') }

  describe 'submiting contact form' do
    context 'signed in user' do
      before do
        allow_any_instance_of(Nuldap).to receive(
          :search).and_return([true, {
            'mail' => ['test@net.com'],
            'displayName' => ['Display Name']
          }])
        login_as(user, :scope => :user)
        visit '/contact'
      end

      context 'all fields filled out properly' do
        before do
          expect(page).to have_text('Select an Issue Type')
          select 'Depositing content', from: 'Issue Type'
          fill_in 'Subject', with: 'nope'
          fill_in 'Message', with: 'yes'
          click_button 'Send'
        end

        specify do
          expect(page).to have_text('Thank you for your message!')
          # Capybara selector bug forces this matcher:
          expect(page).to have_selector(
            :xpath, '//input[@id="contact_form_subject" and not(@value)]')
          # Capybara selector bug forces this matcher:
          expect(page).not_to have_selector('option[selected]')
          expect(page).to have_text('Select an Issue Type')
          expect(page).to have_field('Message', with: '')
          expect(page).to have_field('Your Name', with: 'Display Name')
          expect(page).to have_field('Your Email', with: 'test@net.com')
        end
      end
    end
  end
end
