require 'rails_helper'

feature 'Catalog', :type => :feature do
  subject { page }
  let(:user) { FactoryGirl.create(:user) }

  describe 'My Collections' do
    let!(:col_user) {
      make_collection(user, {
        visibility: 'restricted', title: 'UserCol', id: 'col_user',
      })
    }
    let!(:col_user2) {
      make_collection(user, {
        visibility: 'restricted', title: 'UserCol2', id: 'col_user2',
      })
    }

    context 'authenticated user' do
      before do
        login_as(user)
        visit '/dashboard/collections'
      end

      it 'can add a collection to another', js: true do
        within('#document_col_user2') do
          click_button('Select an action')
          expect(page).not_to have_link('Remove from Collection')
          click_link('Add to Collection')
        end
        choose 'UserCol'
        expect {
          click_button('Update Collection')
        }.to change { col_user.reload.members.count }.by(1)
        expect(current_path).to eq('/collections/col_user')
        within '.table-zebra-striped' do
          expect(page).to have_text('UserCol2')
          expect(page).to have_button('Select an action')
        end
      end
    end
  end
end
