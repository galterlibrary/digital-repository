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

  describe 'edit' do
    context 'logged in owner' do
      before do
        login_as(@user, :scope => :user)
        visit "/files/#{@file.id}"
      end

      describe 'changing permissions' do
        context 'custom groups' do
          before do
            @role = Role.create(name: 'ba-cla', description: 'Cleaning and meaining it.')
            @user.add_role('ba-cla')
            click_link 'Edit'
            click_link 'Permissions'
          end

          it 'shows group descriptions in the select box', js: true do
            select 'Cleaning and meaining it.', from: 'new_group_name_skel'
            select 'Edit', from: 'new_group_permission_skel'
            click_button 'add_new_group_skel'
            expect(page).to have_text('ba-cla')
          end
        end
      end

      describe 'autocomplete', js: true do
        it 'triggers autocomplete for appropriate fields' do
          click_link 'Edit'

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:results).and_return({ id: 1, label: 'ABC' })
          )
          execute_script("$('#generic_file_subject').val('AB').trigger('keydown')")
          expect(page).to have_text('ABC')

          allow_any_instance_of(Nuldap).to(receive(:multi_search).and_return(
            { 'uid' => ['abc'], 'displayName' => ['User X'] }
          ))
          execute_script("$('#generic_file_creator').val('Use').trigger('keydown')")
          expect(page).to have_text('User X')

          allow_any_instance_of(Nuldap).to(receive(:multi_search).and_return(
            { 'uid' => ['bcd'], 'displayName' => ['User Y'] }
          ))
          execute_script("$('#generic_file_contributor').val('Use').trigger('keydown')")
          expect(page).to have_text('User Y')
        end

        it 'triggers autocomplete on keydown for newly added fields' do
          click_link 'Edit'
          # Also tests id corrections for new multi-fields
          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:results).and_return({ id: 1, label: 'ABC' })
          )
          fill_in 'generic_file_subject', with: 'Advanced coloring'
          within(:css, 'div.generic_file_subject') do
            click_button('Add')
            execute_script("$('#generic_file_subject1').val('AB').trigger('keydown')")
          end
          expect(page).to have_text('ABC')

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:results).and_return({ id: 1, label: 'BCD' })
          )
          within(:css, 'div.generic_file_subject') do
            click_button('Add')
            execute_script("$('#generic_file_subject2').val('BC').trigger('keydown')")
          end
          expect(page).to have_text('BCD')
        end

        it 'triggers autocomplete on keydown for additional fields on page load' do
          # Also tests id corrections on page load
          @file.subject = ['Baa', 'Black', 'Sheep']
          @file.save
          click_link 'Edit'

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:results).and_return({ id: 1, label: 'BCD' })
          )
          execute_script("$('#generic_file_subject1').val('BC').trigger('keydown')")
          expect(page).to have_text('BCD')

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:results).and_return({ id: 1, label: 'CDE' })
          )
          execute_script("$('#generic_file_subject2').val('CD').trigger('keydown')")
          expect(page).to have_text('CDE')
        end
      end
    end
  end
end
