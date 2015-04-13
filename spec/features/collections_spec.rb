require 'rails_helper'

feature "Collections", :type => :feature do
  let(:user) { FactoryGirl.create(:user) }
  let(:chi_box) {
    make_collection(user, { title: 'Chinese box' })
  }
  let(:red_box) {
    make_collection(user, { title: 'Red box', page_number: 1 })
  }
  let(:black_box) {
    make_collection(user, { title: 'Black box', page_number: 2 })
  }
  let(:ring) {
    make_generic_file(user, { title: ['Ring of dexterity +9999'] })
  }

  describe 'viewing collection containing collections' do
    before do
      chi_box.members = [red_box, black_box]
      chi_box.save!
      login_as(user, :scope => :user)
      visit("/collections/#{chi_box.id}")
    end

    subject { page }

    it { is_expected.not_to have_text('Number of pages') }
    it { is_expected.to have_text('Total Items') }
    it { is_expected.to have_text('Not a member of any collections') }

    specify {
      expect(find_link('Display all details of Red box')['href']).to eq(
        "/collections/#{red_box.id}")
      expect(find_link('Display all details of Black box')['href']).to eq(
        "/collections/#{black_box.id}")
    }

    it 'shows the number of items' do
      expect(find(:xpath, '//span[@itemprop="total_items"]').text).to eq('2')
    end

    it 'lists collection membership' do
      click_link('Display all details of Red box')
      expect(page).to have_text('Member of:')
      expect(find_link('Chinese box')['href']).to eq(
        "/collections/#{chi_box.id}")
    end
  end

  describe 'viewing collection containing mixed type members' do
    before do
      chi_box.members = [red_box, black_box, ring]
      chi_box.save!
      login_as(user, :scope => :user)
      visit("/collections/#{chi_box.id}")
    end

    subject { page }

    it { is_expected.not_to have_text('Number of pages') }
    it { is_expected.to have_text('Total Items') }
    specify {
      expect(find_link('Display all details of Red box')['href']).to eq(
        "/collections/#{red_box.id}")
      expect(find_link('Display all details of Black box')['href']).to eq(
        "/collections/#{black_box.id}")
      expect(find_link('Ring of dexterity +9999')['href']).to eq(
        "/files/#{ring.id}")
    }

    it 'shows the number of items' do
      expect(find(:xpath, '//span[@itemprop="total_items"]').text).to eq('3')
    end
  end

  describe 'editing collection containing collections' do
    before do
      chi_box.members = [red_box, black_box]
      chi_box.save!
      login_as(user, :scope => :user)
      visit("/collections/#{chi_box.id}/edit")
    end

    subject { page }

    specify {
      expect(find_link('Display all details of Red box')['href']).to eq(
        "/collections/#{red_box.id}")
      expect(find_link('Display all details of Black box')['href']).to eq(
        "/collections/#{black_box.id}")
    }
  end
end
