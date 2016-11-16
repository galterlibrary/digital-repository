require 'rails_helper'

feature "MutiPageCollections", :type => :feature do
  let(:user) { FactoryGirl.create(:user) }
  let(:collection) {
    make_collection(user, { title: 'Book of lies', multi_page: true })
  }
  let(:lie1) {
    make_generic_file(user, { title: ['Nope'], page_number: 1 })
  }
  let(:lie2) {
    make_generic_file(user, { title: ['Yep'], page_number: 2 })
  }
  let(:all_lies) {
    make_generic_file(user, { title: ['Yep and Nope'] })
  }

  describe 'viewing single-page collection' do
    before do
      collection.members = [lie1]
      collection.combined_file = all_lies
      collection.save!
      login_as(user, :scope => :user)
      visit("/collections/#{collection.id}")
    end

    subject { page }

    specify {
      expect(page).to have_link('Launch Viewer')
      expect(page).to have_css('img[src*="iiif-logo"]')
      expect(page).to have_css("a[href*='#{iiif_apis_manifest_url(collection.id)}']")
    }
  end

  describe 'viewing collection' do
    before do
      collection.members = [lie1, lie2]
      collection.combined_file = all_lies
      collection.save!
      login_as(user, :scope => :user)
      visit("/collections/#{collection.id}")
    end

    subject { page }

    specify {
      expect(page).to have_link('Launch Viewer')
      expect(page).to have_css('img[src*="iiif-logo"]')
      expect(page).to have_css("a[href*='#{iiif_apis_manifest_url(collection.id)}']")
      expect(page).to have_text('Number of pages')
      expect(page).not_to have_text('Total Items')
      expect(page).to have_text('Pages in this Collection')
      expect(page).to have_link('View Combined Pages')
      expect(page).to have_select('sort', selected: 'page number ▲')
    }

    it 'shows the number of pages' do
      expect(find(:xpath, '//span[@itemprop="number_of_pages"]').text).to eq('2')
    end
  end
end
