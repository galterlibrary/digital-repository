require 'rails_helper'

feature 'Catalog', :type => :feature do
  subject { page }
  let(:user) { FactoryGirl.create(:user) }

  describe '#index' do
    let!(:gf_public) {
      make_generic_file(user, {
        mesh: ['cancer'], lcsh: ['neoplasm'], visibility: 'open', title: ['ABC']
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
      })
    }

    let!(:col_stranger) {
      make_collection(user, {
        visibility: 'restricted', title: 'StrangeCol', id: 'col_stranger',
      })
    }

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

      it { is_expected.to have_text('ABC') }
      it { is_expected.not_to have_text('BCD') }
      it { is_expected.not_to have_text('DEF') }
      it { is_expected.not_to have_text('ZZZ') }
      it { is_expected.not_to have_button('Add to Collection') }
      it { is_expected.not_to have_selector('#catalogCollections') }
    end

    context 'authenticated user' do
      before do
        login_as(user)
        visit '/catalog'
      end

      it { is_expected.to have_text('ABC') }
      it { is_expected.to have_text('BCD') }
      it { is_expected.to have_text('DEF') }
      it { is_expected.not_to have_text('ZZZ') }
      it { is_expected.not_to have_button('Add to Collection') }
      it { is_expected.not_to have_selector('#catalogCollections') }

      context 'with admin role' do
        before do
          Role.create!(name: 'admin')
          user.add_role('admin')
          visit '/catalog'
        end

        it { is_expected.to have_text('ABC') }
        it { is_expected.to have_text('BCD') }
        it { is_expected.to have_text('DEF') }
        it { is_expected.to have_text('ZZZ') }
        it { is_expected.to have_button('Add to Collection') }
        it { is_expected.to have_selector('#catalogCollections') }
        it { is_expected.to have_selector('input#id_col_user') }
        it { is_expected.to have_selector('input#id_col_stranger') }
      end

      context 'with editor role' do
        before do
          Role.create!(name: 'editor')
          user.add_role('editor')
          visit '/catalog'
        end

        it { is_expected.to have_text('ABC') }
        it { is_expected.to have_text('BCD') }
        it { is_expected.to have_text('DEF') }
        it { is_expected.to have_text('ZZZ') }
      end
    end
  end
end
