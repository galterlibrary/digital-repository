require 'rails_helper'

feature "Dashboard/Collections", :type => :feature do
  let(:user) { FactoryGirl.create(:user) }
  let!(:chi_box) {
    make_collection(user, { title: 'Chinese box' })
  }
  let!(:red_box) {
    make_collection(user, { title: 'Red box', page_number: 1 })
  }
  let!(:black_box) {
    make_collection(user, { title: 'Black box', page_number: 2 })
  }
  let!(:ring) {
    make_generic_file(user, { title: ['Ring of dexterity +9999'] })
  }

  describe 'visibility' do
    before do
      login_as(user, :scope => :user)
    end

    it 'lists the visibilities with a links to edit' do
      black_box.visibility = 'authenticated'
      black_box.save!
      red_box.visibility = 'restricted'
      red_box.save!
      visit "/dashboard/collections"
      expect(page).to have_link("permission_#{chi_box.id}",
                                text: 'Open Access (recommended)')
      expect(page).to have_link("permission_#{black_box.id}",
                                text: 'Northwestern University')
      expect(page).to have_link("permission_#{red_box.id}",
                                text: 'Private')
    end
  end
end
