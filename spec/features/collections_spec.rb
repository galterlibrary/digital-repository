require 'rails_helper'

feature "Collections", :type => :feature do
  subject { page }
  let(:user) { FactoryGirl.create(:user) }
  let(:chi_box) {
    make_collection(user, { title: 'Chinese box' })
  }
  let(:red_box) {
    make_collection(user, { title: 'Red box' })
  }
  let(:black_box) {
    make_collection(user, { title: 'Black box' })
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
    it { is_expected.to have_text('Total Items 3') }
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

  describe 'viewing' do
    before do
      chi_box.members << black_box
      chi_box.save!
    end

    it 'hides private_note from unprivileged users' do
      chi_box.update_attributes(:tag => ['TAG'], :private_note => ['NOTE'])
      visit("/collections/#{chi_box.id}")
      expect(page).not_to have_text('NOTE')
    end

    context 'as an authenticated admin user' do
      let(:priv_col) {
        make_collection(user, { title: 'Invisible', visibility: 'open' }) }
      before do
        login_as(create(:admin_user))
      end

      it 'sorts by tile asc' do
        chi_box.members << ring
        chi_box.save!
        visit "/collections/#{chi_box.id}"
        is_expected.to have_select('sort', selected: 'title ▲')
      end

      it 'does not offer page number sort option' do
        chi_box.members << ring
        chi_box.save!
        visit "/collections/#{chi_box.id}"
        expect(page.html).not_to include('page number ▲')
      end

      it 'lists private members for admin users' do
        chi_box.members << ring
        chi_box.members << priv_col
        chi_box.save!
        visit "/collections/#{chi_box.id}"
        expect(page).to have_link('Ring of dexterity +9999')
        expect(page).to have_link('Invisible')
      end

      it 'lists the action menus', js: true do
        visit "/collections/#{chi_box.id}"
        expect(page).to have_button('Actions')
        within ("#document_#{black_box.id}") do
          click_button('Select an action')
          expect(page).to have_link('Delete Collection')
          expect(page).not_to have_link('Add to Collection')
          expect(page).to have_link('Edit Collection')
          expect(page).to have_link('Remove from Collection')
        end
      end

      it 'can remove a collection member', js: true do
        chi_box.members << red_box
        chi_box.save!
        visit "/collections/#{chi_box.id}"
        within ("#document_#{black_box.id}") do
          click_button('Select an action')
          expect {
            click_link('Remove from Collection')
          }.to change { chi_box.reload.members.count }.by(-1)
        end
        expect(chi_box.member_ids).to eq([red_box.id])
      end

      it 'can remove a file member', js: true do
        chi_box.members << ring
        chi_box.save!
        visit "/collections/#{chi_box.id}"
        within ("#document_#{ring.id}") do
          click_button('Select an action')
          expect {
            click_link('Remove from Collection')
          }.to change { chi_box.reload.members.count }.by(-1)
        end
        expect(chi_box.member_ids).to eq([black_box.id])
      end
    end

    context 'as an authenticated user with edit permissions' do
      before do
        login_as(user, :scope => :user)
      end

      describe 'shows all filled out fields' do
        before do
          chi_box.update_attributes(
            :tag => ['TAG'],
            :resource_type => ['RES'],
            :rights => ['RIGH'],
            :creator => ['CRE'],
            :contributor => ['CONT'],
            :description => 'BLAH',
            :abstract => ['ABST'],
            :bibliographic_citation => ['CIT'],
            :related_url => ['URL'],
            :publisher => ['PUB'],
            :identifier => ['ID'],
            :language => ['LANG'],
            :mesh => ['MESH'],
            :lcsh => ['LCSH'],
            :subject_geographic => ['GEO'],
            :subject_name => ['NAME'],
            :based_near => ['NEAR'],
            :digital_origin => ['ORIG'],
            :original_publisher => ['OPUB'],
            :private_note => ['NOTE'],
          )
          visit("/collections/#{chi_box.id}")
        end

        it 'shows the fields' do
          expect(page).to have_text('TAG')
          expect(page).to have_text('RES')
          expect(page).to have_text('RIGH')
          expect(page).to have_text('CRE')
          expect(page).to have_text('CONT')
          expect(page).to have_text('BLAH')
          expect(page).to have_text('ABST')
          expect(page).to have_text('CIT')
          expect(page).to have_text('URL')
          expect(page).to have_text('PUB')
          expect(page).to have_text('ID')
          expect(page).to have_text('LANG')
          expect(page).to have_text('MESH')
          expect(page).to have_text('LCSH')
          expect(page).to have_text('GEO')
          expect(page).to have_text('NAME')
          expect(page).to have_text('NEAR')
          expect(page).to have_text('ORIG')
          expect(page).to have_text('OPUB')
          expect(page).to have_text('NOTE')
        end
      end

      it 'lists the action menus', js: true do
        visit "/collections/#{chi_box.id}"
        expect(page).to have_button('Actions')
        within ("#document_#{black_box.id}") do
          click_button('Select an action')
          expect(page).not_to have_link('Delete Collection')
          expect(page).not_to have_link('Add to Collection')
          expect(page).to have_link('Edit Collection')
          expect(page).to have_link('Remove from Collection')
        end
      end

      it 'can remove a collection member', js: true do
        chi_box.members << red_box
        chi_box.save!
        visit "/collections/#{chi_box.id}"
        within ("#document_#{black_box.id}") do
          click_button('Select an action')
          expect {
            click_link('Remove from Collection')
          }.to change { chi_box.reload.members.count }.by(-1)
        end
        expect(chi_box.member_ids).to eq([red_box.id])
      end

      it 'can remove a file member', js: true do
        chi_box.members << ring
        chi_box.save!
        visit "/collections/#{chi_box.id}"
        within ("#document_#{ring.id}") do
          click_button('Select an action')
          expect {
            click_link('Remove from Collection')
          }.to change { chi_box.reload.members.count }.by(-1)
        end
        expect(chi_box.member_ids).to eq([black_box.id])
      end

      it 'lists the open visibility' do
        visit "/collections/#{chi_box.id}"
        within(:css, 'h1.visibility') do
          expect(page).to have_link('Open Access (recommended)')
          click_link('Open Access (recommended)')
        end
        expect(page).to have_text('Share With ')
      end

      it 'lists the private visibility' do
        chi_box.visibility = 'restricted'
        chi_box.save!
        visit "/collections/#{chi_box.id}"
        within(:css, 'h1.visibility') do
          expect(page).to have_link('Private')
        end
      end

      it 'lists the authenticated visibility' do
        chi_box.visibility = 'authenticated'
        chi_box.save!
        visit "/collections/#{chi_box.id}"
        within(:css, 'h1.visibility') do
          expect(page).to have_link('Northwestern University')
        end
      end
    end

    context 'as an authenticated user without edit permissions' do
      before do
        login_as(create(:user), :scope => :user)
      end

      it 'does not list the action menus' do
        visit "/collections/#{chi_box.id}"
        expect(page).not_to have_button('Actions')
        within ("#document_#{black_box.id}") do
          expect(page).not_to have_button('Select an action')
        end
      end

      it 'lists the open visibility without a link' do
        visit "/collections/#{chi_box.id}"
        within(:css, 'h1.visibility') do
          expect(page).to have_text('Open Access (recommended)')
          expect(page).not_to have_link('Open Access (recommended)')
        end
      end
    end

    context 'as an unauthenticated user' do
      it 'does not list the action menus' do
        visit "/collections/#{chi_box.id}"
        expect(page).not_to have_button('Actions')
        within ("#document_#{black_box.id}") do
          expect(page).not_to have_button('Select an action')
        end
      end

      it 'lists the open visibility without a link' do
        visit "/collections/#{chi_box.id}"
        within(:css, 'h1.visibility') do
          expect(page).to have_text('Open Access (recommended)')
          expect(page).not_to have_link('Open Access (recommended)')
        end
      end

      describe 'collection links to a combined file' do
        let(:combined) { make_generic_file(user) }

        before do
          chi_box.combined_file = combined
          chi_box.save!
        end

        it 'lists the action menu' do
          visit "/collections/#{chi_box.id}"
          expect(page).to have_button('Actions')
        end
      end
    end
  end

  describe 'new' do
    context 'logged in owner' do
      before do
        login_as(user, :scope => :user)
        visit "/collections/new"
      end

      it { is_expected.to have_button('Create') }
    end
  end

  describe 'updating' do
    context 'logged in owner' do
      before do
        login_as(user, :scope => :user)
        visit "/collections/#{chi_box.id}/edit"
      end

      describe 'adding members', js: true do
        before do
          red_box; ring
          chi_box.update_attributes(multi_page: true)
          visit '/dashboard/files'
        end

        it 'adds the ring in the Chinese Box and keeps the multi page settings' do
          check "batch_document_#{ring.id}"
          click_button 'Add to Collection'
          choose "id_#{chi_box.id}"
          click_button 'Update Collection'
          expect(page).to have_text('Collection was successfully updated')
          expect(page).to have_link('Ring of dexterity +9999')
          expect(page).to have_text('Number of pages')
          expect(page).to have_text('Collection was successfully updated')
          expect(chi_box.reload.multi_page).to be_truthy
        end
      end
    end
  end

  describe 'editing' do
    context 'logged in owner' do
      before do
        login_as(user, :scope => :user)
        visit "/collections/#{chi_box.id}/edit"
      end

      it { is_expected.to have_button('Save') }
      it { is_expected.not_to have_text('* Resource type(s)') }
      it { is_expected.to have_text('* Title') }
      it { is_expected.not_to have_text('* Creator') }
      it { is_expected.to have_text('* Keyword') }
      it { is_expected.not_to have_text('* Rights') }

      describe 'descriptions' do
        it 'can access the descriptions tab' do
          expect(page).to have_text('Resource type')
        end
      end

      describe 'permissions' do
        it 'shows proper label in the visibility help tooltip', js: true do
          click_link 'Permissions'
          within(:css, 'span#visibility_tooltip') do
            expect(find('a')['data-content']).to include('Open Access (recommended)')
          end
        end

        it 'can change visibility', js: true do
          click_link 'Permissions'
          expect(find_field('visibility_restricted')).not_to be_checked
          expect(find_field('visibility_open')).to be_checked
          choose 'visibility_restricted'
          click_button 'Save'
          visit "/collections/#{chi_box.id}/edit"
          click_link 'Permissions'
          expect(find_field('visibility_open')).not_to be_checked
          expect(find_field('visibility_restricted')).to be_checked
        end

        it 'can add access to a group', js: true do
          Role.create(name: 'ba-cla')
          user.add_role('ba-cla')
          visit "/collections/#{chi_box.id}/edit"
          click_link 'Permissions'
          select 'ba-cla', from: 'new_group_name_skel'
          select 'Edit', from: 'new_group_permission_skel'
          click_button 'add_new_group_skel'
          click_button 'Save'
          visit "/collections/#{chi_box.id}/edit"
          click_link 'Permissions'
          expect(page).to have_text('ba-cla')
        end

        it 'can add access to another user', js: true do
          create(:user, username: 'zdenek101', display_name: 'Zdenek Smetana')
          click_link 'Permissions'
          find('.select2-choice').click
          page.execute_script(
            "$('#s2id_autogen1_search').val('zde').trigger('keyup-change');")
          find('.select2-result-label').click
          expect(page).to have_text('Zdenek Smetana (zdenek101)')
          select 'Edit', from: 'new_user_permission_skel'
          click_button 'add_new_user_skel'
          click_button 'Save'
          visit "/collections/#{chi_box.id}/edit"
          click_link 'Permissions'
          expect(page).to have_text('zdenek101')
        end

        it 'can remove access from a user', js: true do
          create(:user, username: 'zdenek101', display_name: 'Zdenek Smetana')
          chi_box.permissions.build(
            name: 'zdenek101', access: 'read', type: 'person' )
          chi_box.save!
          visit "/collections/#{chi_box.id}/edit"
          click_link 'Permissions'
          expect(page).to have_text('zdenek101')
          zdenek = find('label', text: 'Zdenek Smetana (zdenek101)')
          zdenek_id = zdenek['for'].gsub(/[^0-9]/, '')
          remove_zdenek = find(
            :xpath, "//button[@data-index='#{zdenek_id}']")
          remove_zdenek.click
          click_button 'Save'
          visit "/collections/#{chi_box.id}/edit"
          click_link 'Permissions'
          expect(page).not_to have_text('zdenek101')
        end
      end # permissions

      describe 'autocomplete', js: true do
        it 'triggers autocomplete for appropriate fields' do
          visit "/collections/#{chi_box.id}/edit"

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:search).and_return({ id: 1, label: 'ABC' })
          )
          execute_script("$('#collection_mesh').val('AB').trigger('keydown')")
          expect(page).to have_text('ABC')

          allow_any_instance_of(Nuldap).to(receive(:multi_search).and_return([
            { 'uid' => ['abc'], 'givenName' => ['User'], 'sn' => ['X'] }
          ]))
          execute_script("$('#collection_creator').val('Use').trigger('keydown')")
          expect(page).to have_text('X, User')

          allow_any_instance_of(Nuldap).to(receive(:multi_search).and_return([
            { 'uid' => ['abc'], 'givenName' => ['User'], 'sn' => ['Y'] }
          ]))
          execute_script("$('#collection_contributor').val('Use').trigger('keydown')")
          expect(page).to have_text('Y, User')

          allow(GeoNamesResource).to(
            receive(:find_location).and_return([
              { label: 'Chicago', value: 'Chicago' },
              { label: 'Ho Chi', value: 'Ho Chi' }
            ]))
          execute_script("$('#collection_based_near').val('Chi').trigger('keydown')")
          expect(page).to have_text('Chicago')
          expect(page).to have_text('Ho Chi')
        end

        it 'triggers autocomplete on keydown for newly added fields' do
          visit "/collections/#{chi_box.id}/edit"

          # Also tests id corrections for new multi-fields
          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:search).and_return({ id: 1, label: 'ABC' })
          )
          fill_in 'collection_mesh', with: 'Advanced coloring'
          within(:css, 'div.collection_mesh') do
            click_button('Add')
            execute_script("$('#collection_mesh1').val('AB').trigger('keydown')")
          end
          expect(page).to have_text('ABC')

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:search).and_return({ id: 1, label: 'BCD' })
          )
          within(:css, 'div.collection_mesh') do
            click_button('Add')
            execute_script("$('#collection_mesh2').val('BC').trigger('keydown')")
          end
          expect(page).to have_text('BCD')
        end

        it 'triggers autocomplete on keydown for additional fields on page load' do
          # Also tests id corrections on page load
          chi_box.mesh = ['Baa', 'Black', 'Sheep']
          chi_box.save
          visit "/collections/#{chi_box.id}/edit"

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:search).and_return({ id: 1, label: 'BCD' })
          )
          execute_script("$('#collection_mesh1').val('BC').trigger('keydown')")
          expect(page).to have_text('BCD')

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:search).and_return({ id: 1, label: 'CDE' })
          )
          execute_script("$('#collection_mesh2').val('CD').trigger('keydown')")
          expect(page).to have_text('CDE')

          allow_any_instance_of(Qa::Authorities::Mesh).to(
            receive(:search).and_return({ id: 1, label: 'FFF' })
          )
          within(:css, 'div.collection_mesh') do
            click_button('Add')
            execute_script("$('#collection_mesh2').val('FF').trigger('keydown')")
          end
          expect(page).to have_text('FFF')
        end
      end # autocomplete

      describe 'boolean fields' do
        it 'displays help icon' do
          expect(subject).to have_link('collection_multi_page_help')
          expect(subject.html).to include('Check if this is a multi-page')
        end
      end

      describe 'title field' do
        it 'displays help icon' do
          expect(subject).to have_link('collection_title_help')
          expect(subject.html).to include('name chosen by the depositor')
        end
      end

      describe 'description field' do
        it 'displays help icon' do
          expect(subject).to have_link('collection_description_help')
          expect(subject.html).to include('Free-text notes')
        end
      end
    end
  end
end
