require 'rails_helper'

feature "Dashboard/Collections", :type => :feature do
  let(:user) { create(:user, username: 'bigboss') }
  describe 'user profile' do
    before do
      login_as(user, :scope => :user)
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
