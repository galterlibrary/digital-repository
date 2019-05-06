require 'rails_helper'
describe 'generic file', :type => :feature do
  before do
    @user = FactoryGirl.create(:user, formal_name: 'Name, Formal')
    @file = GenericFile.new(
      abstract: ['testa'], bibliographic_citation: ['cit'],
      digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
      subject_geographic: ['geo'], subject_name: ['subjn'],
      visibility: 'open', page_number: '', acknowledgments: ['ack1'],
      grants_and_funding: ['gaf1'], doi: ['doi:abcdoi'], ark: ['ark:/ark1'],
      private_note: ['pri note']
    )
    @file.apply_depositor_metadata(@user.user_key)
    @file.save!
  end

  subject { page }

  describe 'show' do
    specify do
      visit "/files/#{@file.id}"
      expect(page).not_to have_text('Resource type')
      expect(page).not_to have_text('Creator')
      expect(page).not_to have_text('Contributor')
      expect(page).to have_text('Abstract')
      expect(page).to have_text('Original Bibliographic Citation')
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
      expect(page).not_to have_text('Page number')
      expect(page).not_to have_text('User Activity')
      expect(page).to have_text('Acknowledgments')
      expect(page).to have_text('ack1')
      expect(page).to have_text('Grants and funding')
      expect(page).to have_text('gaf1')
      expect(page).to have_link('abcdoi', href: 'https://doi.org/abcdoi')
      expect(page).to have_link('ark:/ark1', href: 'http://n2t.net/ark:/ark1')
      expect(page).not_to have_text('Private Note')
      expect(page).not_to have_text('pri note')
      expect(page).to have_link('Download the file')
    end

    describe 'json' do
      specify do
        @file.title = ['Title']
        @file.creator = ['Creator']
        @file.save
        visit "/files/#{@file.id}.json"
        json = JSON.parse(page.text)
        expect(json['Abstract']).to have_text('testa')
        expect(json['Title']).to have_text(['Title'])
        expect(json['Creator']).to have_text(['Creator'])
        expect(json['uri']).to include("files/#{@file.id}")
        expect(json['DOI']).to have_text(['doi:abcdoi'])
      end
    end

    it 'shows private_note to the owner' do
      login_as(@user, :scope => :user)
      visit "/files/#{@file.id}"
      expect(page).to have_text('Private Note')
      expect(page).to have_text('pri note')
    end

    it 'hides links to Mendeley and Zotero' do
      visit "/files/#{@file.id}"
      expect(page).not_to have_text('Mendeley')
      expect(page).not_to have_text('Zotero')
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
        allow_any_instance_of(GenericFile).to receive(
          :date_uploaded).and_return(Time.now)
        visit "/files/#{@file.id}"
        expect(page).to have_text('Audit Status')
        expect(page).to have_text('Mime type')
        expect(page).to have_text('File size')
        expect(page).to have_text('48.5 kB')
      end
    end

    describe 'activity log' do
      it 'hides log from the unprivileged users' do
        login_as(create(:user), :scope => :user)
        visit "/files/#{@file.id}"
        expect(page).not_to have_text('User Activity')
      end

      it 'hides details from the anonymous users' do
        visit "/files/#{@file.id}"
        expect(page).not_to have_text('User Activity')
      end

      it 'shows details to the owner' do
        login_as(@user, :scope => :user)
        visit "/files/#{@file.id}"
        expect(page).to have_text('User Activity')
      end

      it 'shows details to the privileged users' do
        user = create(:user)
        allow_any_instance_of(GenericFile).to receive(
          :file_format).and_return('png')
        allow_any_instance_of(GenericFile).to receive(
          :date_uploaded).and_return(Time.now)
        user.add_role(Role.create(name: 'editor').name)
        login_as(user, :scope => :user)
        visit "/files/#{@file.id}"
        expect(page).to have_text('User Activity')
      end
    end

    describe 'IIIF preview' do
      context 'Riff-supported type' do
        before do
          allow_any_instance_of(GenericFile).to receive(
            :mime_type).and_return('image/png')
          visit "/files/#{@file.id}"
        end

        it { is_expected.to have_text('Launch Preview') }
      end

      context 'Riff-supported type' do
        before do
          allow_any_instance_of(GenericFile).to receive(
            :mime_type).and_return('application/pdf')
          visit "/files/#{@file.id}"
        end

        it { is_expected.not_to have_text('Launch Preview') }
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
        allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([])
        allow_any_instance_of(Nuldap).to receive(
          :search).and_return([true, {
            'mail' => ['a@b.c'],
            'sn' => ['Name'],
            'givenName' => ['Formal']
          }])
        login_as(@user, :scope => :user)
        visit "/batches/#{@batch.id}/edit"
      end

      describe 'custom metadata' do
        it 'can update all custom metadata fields', js: true do
          click_button('Show Additional Fields')
          # Mandatory
          fill_in 'generic_file_tag', with: 'something'
          expect(page).to have_field(
            'generic_file_creator', with: 'Name, Formal')
          fill_in 'generic_file_creator', with: 'someone'
          select 'Attribution 3.0 United States', from: 'generic_file_rights'

          # Custom
          fill_in 'generic_file_abstract', with: 'abs'
          fill_in 'generic_file_bibliographic_citation', with: 'cit'
          fill_in 'generic_file_acknowledgments', with: 'ack1'
          fill_in 'generic_file_grants_and_funding', with: 'gaf1'
          fill_in 'generic_file_lcsh', with: 'lcsh'
          fill_in 'generic_file_mesh', with: 'mesh'
          fill_in 'generic_file_subject_geographic', with: 'geo'
          fill_in 'generic_file_subject_name', with: 'subjn'
          fill_in 'generic_file_doi', with: 'doi'
          fill_in 'generic_file_ark', with: 'ark'
          fill_in 'generic_file_private_note', with: 'note'

          expect(page).not_to have_text('Digital origin')

          click_button('Save')

          expect(current_path).to eq('/dashboard/files')
          expect(page).to have_text('Your files are being processed')

          @new_file.reload
          expect(@new_file.abstract).to eq(['abs'])
          expect(@new_file.bibliographic_citation).to eq(['cit'])
          expect(@new_file.acknowledgments).to eq(['ack1'])
          expect(@new_file.grants_and_funding).to eq(['gaf1'])
          expect(@new_file.lcsh).to eq(['lcsh'])
          expect(@new_file.mesh).to eq(['mesh'])
          expect(@new_file.subject_geographic).to eq(['geo'])
          expect(@new_file.subject_name).to eq(['subjn'])
          expect(@new_file.doi).to eq(['doi'])
          expect(@new_file.ark).to eq(['ark'])
          expect(@new_file.private_note).to eq(['note'])
        end
      end

      describe 'autocomplete', :vcr, js: true do
        it 'works like in regular gf edit' do
          click_button('Show Additional Fields')

          execute_script("$('#generic_file_mesh').val('AB').trigger('keydown')")
          expect(page).to have_text('Abdomen')
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
          expect(page).to have_link('Acknowledgments')
          expect(page).to have_link('Grants and funding')
          expect(page).not_to have_link('Digital origin')
          expect(page).to have_link('Original Bibliographic Citation')
          expect(page).to have_link('Subject: LCSH')
          expect(page).to have_link('Subject: MESH')
          expect(page).to have_link('Subject: Geographic Name')
          expect(page).to have_link('Subject: Name')
        end
      end

      describe 'autocomplete', :vcr, js: true do
        it 'works like in regular gf edit' do
          click_link('Subject: MESH')
          
          execute_script("$('#generic_file_mesh').val('books').trigger('keydown')")
          expect(page).to have_text('Textbooks')
        end
      end
    end
  end

  describe 'edit Page' do
    describe 'common elements' do
      before do
        make_page(@user, visibility: 'open', id: 'page1')
        login_as(@user, :scope => :user)
        visit '/files/page1'
        click_link 'Edit'
      end

      specify do
        expect(page).to have_button('Save')
        expect(page).to have_text('* Resource type(s)')
        expect(page).to have_text('* Title')
        expect(page).to have_text('* Creator')
        expect(page).to have_text('* Keyword')
        expect(page).to have_text('* Rights')
      end

      it 'can save changes to fields' do
        select 'Animation', from: 'Resource type'
        select 'All rights reserved', from: 'Rights'
        fill_in 'Keyword', with: 'KEY'
        fill_in 'Creator', with: 'God'
        within '#descriptions_display' do
          click_button 'Save'
        end
        expect(current_path).to eq('/files/page1')
        expect(page).to have_text('Animation')
        expect(page).to have_text('KEY')
        expect(page).to have_text('God')
        expect(page).to have_link('All rights reserved')
      end

      it 'will not save unless license is selected' do
        select 'Animation', from: 'Resource type'
        fill_in 'Keyword', with: 'KEY'
        fill_in 'Creator', with: 'God'
        within '#descriptions_display' do
          click_button 'Save'
        end
        expect(current_path).to eq('/files/page1/edit')
      end
    end
  end

  describe 'edit' ,driver: :poltergeist_no_js_errors do
    subject { page }
    context 'logged in owner' do
      before do
        login_as(@user, :scope => :user)
        visit "/files/#{@file.id}"
      end

      describe 'common elements' do
        before { click_link 'Edit' }
        specify do
          expect(page).to have_button('Save')
          expect(page).to have_text('* Resource type(s)')
          expect(page).to have_text('* Title')
          expect(page).to have_text('* Creator')
          expect(page).to have_text('* Keyword')
          expect(page).to have_text('* Rights')
        end
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
          before do
            allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
              {
                'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'],
                'uid' => ['zby101']
              }
            ])
          end

          it 'triggers name validation for appropriate fields' do
            click_link 'Edit'
            execute_script("$('#generic_file_creator').val('Zbys').trigger('blur')")
            within 'div.generic_file_creator' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
              expect(find('input#generic_file_creator').value).to eq(
                'Bogdanca, Zbyszko')
              expect(page).not_to have_link('Vivo Profile')
            end

            execute_script(
              "$('#generic_file_contributor').val('Zbys').trigger('blur')")
            within 'div.generic_file_contributor' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
              expect(find('input#generic_file_contributor').value).to eq(
                'Bogdanca, Zbyszko')
              expect(page).not_to have_link('Vivo Profile')
            end
          end

          context 'with middle name' do
            before do
              allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
                {
                  'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'],
                  'uid' => ['zby101'], 'nuMiddleName' => ['z']
                }
              ])
            end

            it 'triggers name validation for appropriate fields' do
              click_link 'Edit'
              execute_script("$('#generic_file_creator').val('Zbys').trigger('blur')")
              within 'div.generic_file_creator' do
                wait_for_ajax
                expect(page).to have_text('"Bogdanca, Zbyszko z" is a valid')
                expect(find('input#generic_file_creator').value).to eq(
                  'Bogdanca, Zbyszko z')
                expect(page).not_to have_link('Vivo Profile')
              end

              execute_script(
                "$('#generic_file_contributor').val('Zbys').trigger('blur')")
              within 'div.generic_file_contributor' do
                expect(page).to have_text('"Bogdanca, Zbyszko z" is a valid')
                expect(find('input#generic_file_contributor').value).to eq(
                  'Bogdanca, Zbyszko z')
                expect(page).not_to have_link('Vivo Profile')
              end
            end
          end

          context 'vivo profile' do
            before do
              create(:net_id_to_vivo_id, netid: 'zby101', vivoid: 'vivo101')
            end

            it 'triggers name validation' do
              click_link 'Edit'
              execute_script("$('#generic_file_creator').val('Zbys').trigger('blur')")
              within 'div.generic_file_creator' do
                expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
                expect(page).to have_link(
                  'Vivo Profile',
                  href: 'http://vfsmvivo.fsm.northwestern.edu/vivo/individual?uri=http%3A%2F%2Fvivo.northwestern.edu%2Findividual%2Fvivo101'
                )
                expect(find('input#generic_file_creator').value).to eq('Bogdanca, Zbyszko')
              end

              execute_script("$('#generic_file_contributor').val('Zbys').trigger('blur')")
              within 'div.generic_file_contributor' do
                expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
                expect(page).to have_link(
                  'Vivo Profile',
                  href: 'http://vfsmvivo.fsm.northwestern.edu/vivo/individual?uri=http%3A%2F%2Fvivo.northwestern.edu%2Findividual%2Fvivo101'
                )
                expect(find('input#generic_file_contributor').value).to eq('Bogdanca, Zbyszko')
              end
            end
          end

          it 'triggers name validation for multi fields on load' do
            @file.creator = ['abc', 'bcd']
            @file.contributor = ['abc', 'bcd']
            @file.save
            click_link 'Edit'

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

          it 'can add a new field to a non-autocomplete form group' do
            click_link 'Edit'
            fill_in 'generic_file_abstract', with: 'Testa'
            within 'div.generic_file_abstract' do
              click_button('Add')
            end
            expect(all('textarea.generic_file_abstract').count).to eq(3)
          end

          it 'triggers name validation for multi fields on newly added fields' do
            skip 'too js heavy to work all the time'
            click_link 'Edit'

            fill_in 'generic_file_creator', with: 'Testa'
            within 'div.generic_file_creator' do
              click_button('Add')
            end

            execute_script("$('#generic_file_creator1').val('Zbys').trigger('blur')")
            wait_for_ajax
            within 'li#generic_file_creator1-ver' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
            end
            expect(find('input#generic_file_creator1').value).to eq('Bogdanca, Zbyszko')

            fill_in 'generic_file_contributor', with: 'Testa'
            within 'div.generic_file_contributor' do
              click_button('Add')
            end
            execute_script("$('#generic_file_contributor1').val('Zbys').trigger('blur')")
            wait_for_ajax
            within 'li#generic_file_contributor1-ver' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
            end
            expect(find('input#generic_file_contributor1').value).to eq('Bogdanca, Zbyszko')
          end

          it 'marks user as invalid after a valid user name is modified to invalid' do
            click_link 'Edit'
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

            execute_script("$('#generic_file_creator').val('Bogdanca, Zbyszko').trigger('blur')")
            within 'div.generic_file_creator' do
              expect(page).to have_text('"Bogdanca, Zbyszko" is a valid')
              click_button('Remove')
            end
            expect(page).not_to have_text('"Bogdanca, Zbyszko" is a valid')
          end
        end
      end

      describe 'autocomplete', :vcr, js: true do
        it 'triggers autocomplete for appropriate fields' do
          click_link 'Edit'

          execute_script("$('#generic_file_mesh').val('survivor').trigger('keydown')")
          expect(page).to have_text('Cancer Survivors')

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

          allow(GeoNamesResource).to(
            receive(:find_location).and_return([
              { label: 'Chicago', value: 'Chicago' },
              { label: 'Ho Chi', value: 'Ho Chi' }
            ]))
          execute_script("$('#generic_file_based_near').val('Chi').trigger('keydown')")
          expect(page).to have_text('Chicago')
          expect(page).to have_text('Ho Chi')
        end

        it 'triggers autocomplete on keydown for newly added fields' do
          click_link 'Edit'
          # Also tests id corrections for new multi-fields
          fill_in 'generic_file_mesh', with: 'Advanced coloring'
          within(:css, 'div.generic_file_mesh') do
            click_button('Add')
            execute_script("$('#generic_file_mesh1').val('coloring').trigger('keydown')")
          end
          expect(page).to have_text('Food Coloring Agents')

          within(:css, 'div.generic_file_mesh') do
            click_button('Add')
            execute_script("$('#generic_file_mesh2').val('color').trigger('keydown')")
          end
          expect(page).to have_text('Color Perception')
        end

        it 'triggers autocomplete on keydown for additional fields on page load', js: true do
          # Also tests id corrections on page load
          @file.mesh = ['Baa', 'Black', 'Sheep']
          @file.save
          click_link 'Edit'

          execute_script("$('#generic_file_mesh1').val('black').trigger('keydown')")
          expect(page).to have_text('Black Widow Spider')

          execute_script("$('#generic_file_mesh2').val('sheep').trigger('keydown')")
          expect(page).to have_text('Sheep Diseases')

          within(:css, 'div.generic_file_mesh') do
            click_button('Add')
            execute_script("$('#generic_file_mesh2').val('spider').trigger('keydown')")
          end
          expect(page).to have_text('Spider Bites')
        end

        context 'with middle name' do
          before do
            allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
              {
                'givenName' => ['User'], 'sn' => ['X'],
                'uid' => ['zby101'], 'nuMiddleName' => ['YZ']
              }
            ])
          end

          it 'shows the middle name in the full name' do
            click_link 'Edit'
            execute_script("$('#generic_file_creator').val('Use').trigger('keydown')")
            expect(page).to have_text('X, User YZ')

          end
        end
      end

      describe 'single-value fields' do
        it 'displays help icon' do
          click_link 'Edit'
          expect(subject.html).to include('generic_file_page_number_help')
          expect(subject.html).to include('Numbers added by the submitter')
        end
      end

      describe 'rights field' do
        it 'displays help icon' do
          click_link 'Edit'
          expect(subject).to have_link('generic_file_rights_help_modal')
          expect(subject.html).to include('Creative Commons licenses')
        end
      end
    end
  end
end
