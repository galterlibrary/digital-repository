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

  describe 'viewing collection' do
    before do
      collection.members = [lie1, lie2]
      collection.combined_file = all_lies
      collection.save!
      login_as(user, :scope => :user)
      visit("/collections/#{collection.id}")
    end

    subject { page }

    it { is_expected.to have_link('Launch Viewer') }
    it { is_expected.to have_text('Number of pages') }
    it { is_expected.not_to have_text('Total Items') }
    it { is_expected.to have_text('Pages in this Collection') }
    it { is_expected.to have_link('View Combined Pages') }

    it 'shows the number of pages' do
      expect(find(:xpath, '//span[@itemprop="number_of_pages"]').text).to eq('2')
    end
  end
end
