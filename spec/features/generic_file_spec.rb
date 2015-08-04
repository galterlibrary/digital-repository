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

    describe 'file details' do
      before do
        allow_any_instance_of(GenericFile).to receive(
          :characterization_terms
        ).and_return(
          {:format_label=>["Portable Network Graphics"],
          :mime_type=>"image/png",
          :file_size=>["48512"],
          :filename=>["synergy.png"]}
        )
      end

      it 'hides details from the unprivileged users' do
        login_as(@user, :scope => :user)
        visit "/files/#{@file.id}"
        expect(page).not_to have_text('Audit Status')
        expect(page).to have_text('Mime type')
        expect(page).to have_text('File size')
      end

      it 'hides details from the anonymous users' do
        visit "/files/#{@file.id}"
        expect(page).not_to have_text('Audit Status')
        expect(page).to have_text('Mime type')
        expect(page).to have_text('File size')
      end

      it 'shows details to the privileged users' do
        allow_any_instance_of(GenericFile).to receive(
          :file_format).and_return('png')
        @user.add_role(Role.create(name: 'editor').name)
        login_as(@user, :scope => :user)
        visit "/files/#{@file.id}"
        expect(page).to have_text('Audit Status')
        expect(page).to have_text('Mime type')
        expect(page).to have_text('File size')
        expect(page).to have_text('48.5 kB')
      end
    end
  end

  describe 'create batch' do
    context 'logged in owner' do
      before do
        @batch = Batch.create
        @new_file = make_generic_file(@user, { label: 'Newnew' })
        @new_file.batch = @batch
        @new_file.save
        login_as(@user, :scope => :user)
        visit "/batches/#{@batch.id}/edit"
      end

      describe 'custom metadata' do
        it 'can update all custom metadata fields', js: true do
          click_button('Show Additional Fields')
          # Mandatory
          fill_in 'generic_file_tag', with: 'something'
          fill_in 'generic_file_creator', with: 'someone'
          select 'Attribution 3.0 United States', from: 'generic_file_rights'

          # Custom
          fill_in 'generic_file_abstract', with: 'abs'
          fill_in 'generic_file_digital_origin', with: 'digo'
          fill_in 'generic_file_bibliographic_citation', with: 'cit'
          fill_in 'generic_file_lcsh', with: 'lcsh'
          fill_in 'generic_file_mesh', with: 'mesh'
          fill_in 'generic_file_subject_geographic', with: 'geo'
          fill_in 'generic_file_subject_name', with: 'subjn'

          click_button('Save')

          expect(current_path).to eq('/dashboard/files')
          expect(page).to have_text('Your files are being processed')

          @new_file.reload
          expect(@new_file.abstract).to eq(['abs'])
          expect(@new_file.digital_origin).to eq(['digo'])
          expect(@new_file.bibliographic_citation).to eq(['cit'])
          expect(@new_file.lcsh).to eq(['lcsh'])
          expect(@new_file.mesh).to eq(['mesh'])
          expect(@new_file.subject_geographic).to eq(['geo'])
          expect(@new_file.subject_name).to eq(['subjn'])
        end
      end

      describe 'autocomplete', js: true do
        it 'works like in regular gf edit' do
          pending 'removing subjects, and moving this to subject: mash'
          click_button('Show Additional Fields')

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:results).and_return({ id: 1, label: 'ABC' })
          )
          execute_script("$('#generic_file_subject').val('AB').trigger('keydown')")
          expect(page).to have_text('ABC')
        end
      end
    end
  end

  describe 'batch edits' do
    context 'logged in owner' do
      before do
        @batch = Batch.create
        @new_file = make_generic_file(@user, { label: 'Newnew', mesh: ['t2'] })
        @new_file.batch = @batch
        @new_file.save
        login_as(@user, :scope => :user)
        visit "/batch_edits/edit?batch_document_ids[]=#{@file.id}&batch_document_ids[]=#{@new_file.id}"
      end

      describe 'custom metadata' do
        it 'does not list the page number field' do
          expect(page).not_to have_link('Page number')
        end

        # Testing updatability of takes too long because JavaScript
        # We trust the upstream tested this.
        it 'lists the custom fields' do
          expect(page).to have_link('Abstract')
          expect(page).to have_link('Digital origin')
          expect(page).to have_link('Bibliographic citation')
          expect(page).to have_link('Subject: LCSH')
          expect(page).to have_link('Subject: MESH')
          expect(page).to have_link('Subject: Geographic Name')
          expect(page).to have_link('Subject: Name')
        end
      end

      describe 'autocomplete', js: true do
        it 'works like in regular gf edit' do
          pending 'removing subjects, and moving this to subject: mash'
          click_link('Subject')

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:results).and_return({ id: 1, label: 'ABC' })
          )
          execute_script("$('#generic_file_subject').val('AB').trigger('keydown')")
          expect(page).to have_text('ABC')
        end
      end
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

      describe 'name verification', js: true do
        context 'invalid users' do
          it 'prints out the message returned from user validation' do
            click_link 'Edit'

            allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([])
            execute_script("$('#generic_file_creator').val('Zbys').trigger('blur')")
            within 'div.generic_file_creator' do
              expect(page).to have_text('"Zbys" not found')
            end
          end
        end

        context 'valid users' do
          it 'triggers name validation for appropriate fields' do
            click_link 'Edit'

            allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
              { 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'] }
            ])

            execute_script("$('#generic_file_creator').val('Zbys').trigger('blur')")
            within 'div.generic_file_creator' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
              expect(find('input#generic_file_creator').value).to eq('Bogdanca, Zbyszko')
            end

            execute_script("$('#generic_file_contributor').val('Zbys').trigger('blur')")
            within 'div.generic_file_contributor' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
              expect(find('input#generic_file_contributor').value).to eq('Bogdanca, Zbyszko')
            end
          end

          it 'triggers name validation for multi fields on load' do
            @file.creator = ['abc', 'bcd']
            @file.contributor = ['abc', 'bcd']
            @file.save
            click_link 'Edit'

            allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
              { 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'] }
            ])

            execute_script("$('#generic_file_creator1').val('Zbys').trigger('blur')")
            within 'div.generic_file_creator' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
              expect(find('input#generic_file_creator1').value).to eq('Bogdanca, Zbyszko')
            end

            execute_script("$('#generic_file_contributor1').val('Zbys').trigger('blur')")
            within 'div.generic_file_contributor' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
              expect(find('input#generic_file_contributor1').value).to eq('Bogdanca, Zbyszko')
            end
          end

          it 'triggers name validation for multi fields on newly added fields' do
            click_link 'Edit'

            allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
              { 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'] }
            ])

            fill_in 'generic_file_creator', with: 'Testa'
            within 'div.generic_file_creator' do
              click_button('Add')
            end

            execute_script("$('#generic_file_creator1').val('Zbys').trigger('blur')")
            within 'li#generic_file_creator1-ver' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
            end
            expect(find('input#generic_file_creator1').value).to eq('Bogdanca, Zbyszko')

            fill_in 'generic_file_contributor', with: 'Testa'
            within 'div.generic_file_contributor' do
              click_button('Add')
            end
            execute_script("$('#generic_file_contributor1').val('Zbys').trigger('blur')")

            within 'li#generic_file_contributor1-ver' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
            end
            expect(find('input#generic_file_contributor1').value).to eq('Bogdanca, Zbyszko')
          end

          it 'marks user as invalid after a valid user name is modified to invalid' do
            click_link 'Edit'

            allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
              { 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'] }
            ])

            execute_script("$('#generic_file_creator').val('Bogdanca, Zbyszko').trigger('blur')")
            within 'div.generic_file_creator' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
            end

            allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([])

            execute_script("$('#generic_file_contributor').val('Zbys').trigger('blur')")
            within 'div.generic_file_contributor' do
              expect(page).not_to have_text('"Bogdanca, Zbyszko" is a valid')
              expect(page).to have_text('User "Zbys" not found')
            end
          end

          it 'removes the validation note when removing a corresponding input' do
            @file.creator = ['asdf']
            @file.save
            click_link 'Edit'

            allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
              { 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'] }
            ])

            execute_script("$('#generic_file_creator').val('Bogdanca, Zbyszko').trigger('blur')")
            within 'div.generic_file_creator' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
              click_button('Remove')
            end
            expect(page).not_to have_text('"Bogdanca, Zbyszko" is a valid')
          end
        end
      end

      describe 'autocomplete', js: true do
        it 'triggers autocomplete for appropriate fields' do
          pending 'removing subjects, and moving this to subject: mash'
          click_link 'Edit'

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:results).and_return({ id: 1, label: 'ABC' })
          )
          execute_script("$('#generic_file_subject').val('AB').trigger('keydown')")
          expect(page).to have_text('ABC')

          allow_any_instance_of(Nuldap).to(receive(:multi_search).and_return([
            { 'uid' => ['abc'], 'givenName' => ['User'], 'sn' => ['X'] }
          ]))
          execute_script("$('#generic_file_creator').val('Use').trigger('keydown')")
          expect(page).to have_text('X, User')

          allow_any_instance_of(Nuldap).to(receive(:multi_search).and_return([
            { 'uid' => ['abc'], 'givenName' => ['User'], 'sn' => ['Y'] }
          ]))
          execute_script("$('#generic_file_contributor').val('Use').trigger('keydown')")
          expect(page).to have_text('Y, User')

          allow_any_instance_of(GeoNamesResource).to(
            receive(:find_location).and_return([
              { label: 'Chicago', value: 'Chicago' },
              { label: 'Ho Chi', value: 'Ho Chi' }
            ]))
          execute_script("$('#generic_file_based_near').val('Chi').trigger('keydown')")
          expect(page).to have_text('Chicago')
          expect(page).to have_text('Ho Chi')
        end

        it 'triggers autocomplete on keydown for newly added fields' do
          pending 'removing subjects, and moving this to subject: mash'
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
          pending 'removing subjects, and moving this to subject: mash'
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

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:results).and_return({ id: 1, label: 'FFF' })
          )
          within(:css, 'div.generic_file_subject') do
            click_button('Add')
            execute_script("$('#generic_file_subject2').val('FF').trigger('keydown')")
          end
          expect(page).to have_text('FFF')
        end
      end
    end
  end
end
