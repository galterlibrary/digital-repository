require 'rails_helper'

feature "HomePage", :type => :feature do
  let(:user) { FactoryGirl.create(:user) }
  describe 'tag cloud' do
    let!(:cancer) {
      make_generic_file(user, {
        mesh: ['cancer'], lcsh: ['neoplasm'], visibility: 'open', title: ['ABC']
      })
    }
    let!(:neuroblastoma) {
      make_generic_file(user, {
        mesh: ['something'], subject_name: ['neoplasm'], visibility: 'open',
        title: ['BCD']
      })
    }

    it 'lists all the subjects in the cloud', js: true do
      visit '/'
      expect(page).to have_link('cancer')
      expect(page).to have_link('neoplasm')
      expect(page).to have_link('something')
    end

    it 'links the subjects in the cloud to the catalog', js: true do
      visit '/'
      click_link 'neoplasm'
      expect(page).to have_text('neoplasm')
      expect(find('span.selected.facet-count').text).to eq('2')
      expect(page).to have_link('cancer')
      expect(page).to have_link('something')
      expect(page).to have_text('ABC')
      expect(page).to have_text('BCD')
    end
  end
end
