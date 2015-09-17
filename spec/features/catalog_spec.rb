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

    context 'anonymous user' do
      before { visit '/catalog' }

      it { is_expected.to have_text('ABC') }
      it { is_expected.not_to have_text('BCD') }
      it { is_expected.not_to have_text('DEF') }
      it { is_expected.not_to have_text('ZZZ') }
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
