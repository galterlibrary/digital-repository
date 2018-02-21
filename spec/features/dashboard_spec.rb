require 'rails_helper'

feature "Dashboard", :type => :feature do
  let(:user) { FactoryGirl.create(:user) }

  describe 'links in "Your statistics"' do
    before do
      make_collection(user)
      make_generic_file(user)
      make_generic_file(user)
      expect_any_instance_of(User).to receive(:all_following) {
        double('all_following', count: 11)
      }
      expect_any_instance_of(User).to receive(:followers) {
        double('followers', count: 22)
      }
      login_as(user, :scope => :user)
      visit "/dashboard"
    end

    it 'links badges' do
      within('#sidebar') do
        expect(page).to have_link('2', href: '/dashboard/files')
        expect(page).to have_link('1', href: '/dashboard/collections')
        expect(page).to have_link('11', href: "/users/#{user.username}#following")
        expect(page).to have_link('22', href: "/users/#{user.username}#followers")
      end
    end
  end
end
