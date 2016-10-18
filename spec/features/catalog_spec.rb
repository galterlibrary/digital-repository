require 'rails_helper'

feature 'Catalog', :type => :feature do
  subject { page }
  let(:user) { FactoryGirl.create(:user) }

  describe 'dangerous things passed in the params' do
    it 'escapes them' do
      visit("/catalog?f%5Btag_sim%5D%5B%5D=Methylphenidate&q=%22'%3E%3Cqss%20a%3DX166950132Y2Z%3E")
      expect(page.html).not_to include('<qss a=X166950132Y2Z>')
    end
  end

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

    it 'does not offer page-number sort option' do
      visit '/catalog'
      expect(page.html).to include('date uploaded ▼')
      expect(page.html).not_to include('page number ▼')
    end

    it 'shows the custom facets' do
      gf_public.collection_ids = col_user.id
      gf_public.update_index
      visit '/catalog'
      within('#facets') do
        expect(page).to have_link('Rights Statement')
        expect(page).not_to have_link('Object Type')
        expect(page).to have_link('Collection')
      end
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
        expect(page).not_to have_link('Private')
        expect(page).not_to have_link('Open Access (recommended)')
        expect(page).not_to have_link('Add to Collection')
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
        expect(page).not_to have_link('Private')
        expect(page).not_to have_link('Open Access (recommended)')
        expect(page).not_to have_link('Delete')
      end

      context 'pagination' do
        before do
          visit '/catalog?per_page=2'
        end

        it 'does not display link to current page' do
          within('.pagination') do
            expect(page).not_to have_link('1')
            within('span') { expect(page).to have_text('1') }
            expect(page).to have_link('2', href: '/catalog?page=2&per_page=2')
          end
        end
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
          expect(page).to have_link(
            'Private',
            href: sufia.edit_generic_file_path(
              gf_private, anchor: "permissions_display"
            )
          )
          expect(page).to have_link(
            'Open Access (recommended)',
            href: sufia.edit_generic_file_path(
              gf_public, anchor: "permissions_display"
            )
          )
          expect(page).to have_link(
            'Northwestern University',
            href: sufia.edit_generic_file_path(
              gf_authenticated, anchor: "permissions_display"
            )
          )
          expect(page).to have_link(
            'Private',
            href: collections.edit_collection_path(
              col_user, anchor: "permissions_display"
            )
          )
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
          expect(page).to have_link(
            'Private',
            href: sufia.edit_generic_file_path(
              gf_private, anchor: "permissions_display"
            )
          )
          expect(page).to have_link(
            'Open Access (recommended)',
            href: sufia.edit_generic_file_path(
              gf_public, anchor: "permissions_display"
            )
          )
          expect(page).to have_link(
            'Northwestern University',
            href: sufia.edit_generic_file_path(
              gf_authenticated, anchor: "permissions_display"
            )
          )
          expect(page).to have_link(
            'Private',
            href: collections.edit_collection_path(
              col_user, anchor: "permissions_display"
            )
          )
          expect(page).not_to have_link('Delete')
        end
      end
    end
  end
end
