require 'rails_helper'

feature "Users", :type => :feature do
  let(:user) { create(:user, username: 'bigboss') }
  describe 'user profile' do
    before do
      login_as(user, :scope => :user)
    end

    context 'modal pop out on anchor passed', js: true do
      it 'does not pop out modal with no anchor' do
        visit '/users/bigboss'
        expect(page).to have_selector('#following', visible: false)
        expect(page).to have_selector('#followers', visible: false)
        expect(page).to have_selector('#followedCollections', visible: false)
      end

      it 'pops out the following modal' do
        visit '/users/bigboss#following'
        expect(page).to have_selector('#following', visible: true)
        expect(page).to have_selector('#followers', visible: false)
        expect(page).to have_selector('#followedCollections', visible: false)
      end

      it 'pops out the followers modal' do
        visit '/users/bigboss#followers'
        expect(page).to have_selector('#following', visible: false)
        expect(page).to have_selector('#followers', visible: true)
        expect(page).to have_selector('#followedCollections', visible: false)
      end

      it 'pops out the followedCollections modal' do
        visit '/users/bigboss#followedCollections'
        expect(page).to have_selector('#following', visible: false)
        expect(page).to have_selector('#followers', visible: false)
        expect(page).to have_selector('#followedCollections', visible: true)
        expect(page).to have_text("You do not follow any collections")
      end
    end

    context 'followedCollections modal' do
      let(:col1) { make_collection(create(:user), title: 'a') }
      let(:col2) { make_collection(create(:user), title: 'c') }
      let(:col3) { make_collection(create(:user), title: 'b') }

      before do
        col1.set_follower(user)
        col2.set_follower(user)
        col3.set_follower(user)
        visit '/users/bigboss#followedCollections'
      end

      specify do
        expect(page).to have_text("Collections you follow")
        expect(page).to have_link('a', href: "/collections/#{col1.id}")
        expect(page).to have_link('b', href: "/collections/#{col3.id}")
        expect(page).to have_link('c', href: "/collections/#{col2.id}")
      end
    end

    context 'vivo profile exists' do
      let!(:n2v) {
        create(:net_id_to_vivo_id, netid: 'bigboss', vivoid: 'vivoboss')
      }

      it 'shows link to vivo profile' do
        visit '/users/bigboss'
        expect(page).to have_link(
          'Vivo Profile',
          href: 'http://vfsmvivo.fsm.northwestern.edu/vivo/individual?uri=http%3A%2F%2Fvivo.northwestern.edu%2Findividual%2Fvivoboss'
        )
      end
    end
  end
end
