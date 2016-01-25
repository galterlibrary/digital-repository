require 'rails_helper'

feature 'Catalog', :type => :feature do
  subject { page }
  let(:user) { FactoryGirl.create(:user) }

  describe '#index' do
    let!(:gf_public) {
      make_generic_file(user, {
        mesh: ['cancer'], lcsh: ['neoplasm'], visibility: 'open',
        title: ['ABC'], rights: ['All rights reserved']
      })
    }
    let!(:gf_private) {
      make_generic_file(user, {
        mesh: ['something'], subject_name: ['neoplasm'], visibility: 'restricted',
        title: ['BCD']
      })
    }
    let!(:gf_authenticated) {
      make_generic_file(user, {
        mesh: ['something'], subject_name: ['neoplasm'], visibility: 'authenticated',
        title: ['DEF']
      })
    }
    let!(:gf_stranger) {
      make_generic_file(FactoryGirl.create(:user), {
        mesh: ['something'], subject_name: ['neoplasm'], visibility: 'restricted',
        title: ['ZZZ']
      })
    }

    let!(:col_user) {
      make_collection(user, {
        visibility: 'restricted', title: 'UserCol', id: 'col_user',
        rights: ['http://creativecommons.org/publicdomain/mark/1.0']
      })
    }

    let!(:col_stranger) {
      make_collection(user, {
        visibility: 'restricted', title: 'StrangeCol', id: 'col_stranger',
      })
    }

    it 'shows the Rights Statement facet' do
      visit '/catalog'
      expect(page).to have_text('Rights Statement')
    end

    it 'does not display blank fields' do
      visit '/catalog'
      expect(page).not_to have_text('Description')
      expect(page).not_to have_text('Keywords')
    end

    it 'displays description when available' do
      gf_public.description = ['Testing 123']
      gf_public.save
      visit '/catalog'
      expect(page).to have_text('Description')
      expect(page).to have_text('Testing 123')
    end

    it 'displays keywords when available' do
      gf_public.tag = ['tag1', 'tag2']
      gf_public.save
      visit '/catalog'
      expect(page).to have_text('Keywords')
      expect(page).to have_text('tag1, tag2')
    end

    context 'anonymous user' do
      before { visit '/catalog' }

      specify do
        expect(page).to have_text('ABC')
        expect(page).not_to have_text('BCD')
        expect(page).not_to have_text('DEF')
        expect(page).not_to have_text('ZZZ')
        expect(page).not_to have_button('Add to Collection')
        expect(page).not_to have_selector('#catalogCollections')
        expect(page).not_to have_link('Delete')
      end
    end

    context 'authenticated user' do
      before do
        login_as(user)
        visit '/catalog'
      end

      specify do
        expect(page).to have_text('ABC')
        expect(page).to have_text('BCD')
        expect(page).to have_text('DEF')
        expect(page).not_to have_text('ZZZ')
        expect(page).not_to have_button('Add to Collection')
        expect(page).not_to have_selector('#catalogCollections')
        expect(page).not_to have_link('Delete')
      end

      context 'with admin role' do
        before do
          Role.create!(name: 'admin')
          user.add_role('admin')
          visit '/catalog'
        end

        specify do
          expect(page).to have_text('ABC')
          expect(page).to have_text('BCD')
          expect(page).to have_text('DEF')
          expect(page).to have_text('ZZZ')
          expect(page).to have_button('Add to Collection')
          expect(page).to have_selector('#catalogCollections')
          expect(page).to have_selector('input#id_col_user')
          expect(page).to have_selector('input#id_col_stranger')
          expect(page).to have_link('Delete')
        end

        it 'can delete an object' do
          expect {
            click_link('deleteButton-col_stranger')
          }.to change { Collection.count }.by(-1)
          expect { col_stranger.reload }.to raise_error(Ldp::Gone)
        end
      end

      context 'with editor role' do
        before do
          Role.create!(name: 'editor')
          user.add_role('editor')
          visit '/catalog'
        end

        specify do
          expect(page).to have_text('ABC')
          expect(page).to have_text('BCD')
          expect(page).to have_text('DEF')
          expect(page).to have_text('ZZZ')
          expect(page).to have_button('Add to Collection')
          expect(page).to have_selector('#catalogCollections')
          expect(page).to have_selector('input#id_col_user')
          expect(page).to have_selector('input#id_col_stranger')
          expect(page).not_to have_link('Delete')
        end
      end
    end
  end
end
