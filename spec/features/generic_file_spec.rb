require 'rails_helper'
describe 'generic file', :type => :feature do
  before do
    GenericFile.delete_all
    @user = FactoryGirl.create(:user)
    #@routes = Sufia::Engine.routes
    @file = GenericFile.new(
      abstract: ['testa'], bibliographic_citation: ['cit'],
      digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
      subject_geographic: ['geo'], subject_name: ['subjn'],
      visibility: 'open'
    )
    @file.apply_depositor_metadata(@user.user_key)
    @file.save!
  end

  after do
    ::GenericFile.delete_all
  end

  describe 'show' do
    it 'hides descriptions with blank values' do
      visit "/files/#{@file.id}"
      expect(page).not_to have_text('Resource type')
      expect(page).not_to have_text('Creator')
      expect(page).not_to have_text('Contributor')
      expect(page).to have_text('Abstract')
      expect(page).to have_text('Bibliographic citation')
      expect(page).not_to have_text('Keyword')
      expect(page).not_to have_text('Rights')
      expect(page).not_to have_text('Publisher')
      expect(page).not_to have_text('Date Created')
      expect(page).to have_text('Subject: MESH')
      expect(page).to have_text('Subject: LCSH')
      expect(page).to have_text('Subject: Geographic Name')
      expect(page).to have_text('Subject: Name')
      expect(page).not_to have_text('Language')
      expect(page).not_to have_text('Identifier')
      expect(page).not_to have_text('Location')
      expect(page).not_to have_text('Related URL')
      expect(page).to have_text('Digital')
    end
  end
end
