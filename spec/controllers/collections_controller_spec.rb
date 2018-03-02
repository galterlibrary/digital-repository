require 'rails_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  before do
    @user = FactoryGirl.create(:user, username: 'badmofo')
    sign_in @user
  end

  describe "#index" do
    before do
      make_collection(@user, title: 'w_user', visibility: 'restricted')
      make_collection(@user, title: 'a_User')
      make_collection(@user, title: 'd_user')
      make_collection(@user, title: 'b_galter')
      make_collection(@user, title: 'a_galter')
      make_collection(@user, title: 'B_IPHAM')
      make_collection(@user, title: 'A_ipham')
    end

    it "should assign proper collection" do
      get :index
      expect(response).to be_successful
      expect(assigns(:document_list).map {|o| o['title_tesim'].first }).to eq([
        'a_galter',
        'A_ipham',
        'a_User',
        'b_galter',
        'B_IPHAM',
        'd_user',
        'w_user'
      ])
    end

    context 'anonymous user' do
      before { sign_out @user }
      it "should assign proper collection" do
        get :index
        expect(response).to be_successful
        expect(assigns(:document_list).map {|o| o['title_tesim'].first }).to eq([
          'a_galter',
          'A_ipham',
          'a_User',
          'b_galter',
          'B_IPHAM',
          'd_user'
        ])
      end
    end
  end

  describe "#destroy" do
    before do
      @file = make_collection(@user, id: 'nukeme')
    end

    it 'does not allow non-admin owner to delete files' do
      expect {
        delete :destroy, id: 'nukeme'
      }.not_to change(Collection, :count)
      expect(flash[:alert]).to match('You are not authorized')
    end

    it 'allows an admin user to delete files' do
      @user = FactoryGirl.create(:user)
      @user.add_role(Role.create(name: 'admin').name)
      sign_in @user

      expect {
        delete :destroy, id: 'nukeme'
      }.to change(Collection, :count).by(-1)
      expect { Collection.find('nukeme') }.to raise_error(Ldp::Gone)
    end
  end

  describe "#show" do
    before do
      @collection = make_collection(
        @user, title: 'something', tag: ['tag'],
        abstract: ['testa'], bibliographic_citation: ['cit'],
        digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
        subject_geographic: ['geo'], subject_name: ['subjn'],
        multi_page: true, original_publisher: ['opub'],
        private_note: ['note']
      )
    end

    it "should assign proper collection" do
      get :show, id: @collection
      expect(response).to be_successful
      expect(assigns(:collection).abstract).to eq(['testa'])
      expect(assigns(:collection).bibliographic_citation).to eq(['cit'])
      expect(assigns(:collection).digital_origin).to eq(['digo'])
      expect(assigns(:collection).mesh).to eq(['mesh'])
      expect(assigns(:collection).lcsh).to eq(['lcsh'])
      expect(assigns(:collection).subject_geographic).to eq(['geo'])
      expect(assigns(:collection).subject_name).to eq(['subjn'])
      expect(assigns(:collection).multi_page).to eq(true)
      expect(assigns(:collection).original_publisher).to eq(['opub'])
      expect(assigns(:collection).private_note).to eq(['note'])
    end
  end

  describe "#create" do
    it 'creates collection' do
      expect {
        post :create, id: @collection, collection: {
          title: 'something', description: 'desc', tag: ['tag'],
          abstract: ['testa'], bibliographic_citation: ['cit'],
          digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
          subject_geographic: ['geo'], subject_name: ['subjn'],
          original_publisher: ['opub'], private_note: ['note']
        }
      }.to change { Collection.count }.by(1)
    end

    it 'populates the custom attributes' do
      post :create, id: @collection, collection: {
        title: 'something', description: 'desc', tag: ['tag'],
        abstract: ['testa'], bibliographic_citation: ['cit'],
        digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
        subject_geographic: ['geo'], subject_name: ['subjn'],
        multi_page: 'true', original_publisher: ['opub'],
        private_note: ['note']
      }
      expect(assigns(:collection).abstract).to eq(['testa'])
      expect(assigns(:collection).bibliographic_citation).to eq(['cit'])
      expect(assigns(:collection).digital_origin).to be_blank
      expect(assigns(:collection).mesh).to eq(['mesh'])
      expect(assigns(:collection).lcsh).to eq(['lcsh'])
      expect(assigns(:collection).subject_geographic).to eq(['geo'])
      expect(assigns(:collection).subject_name).to eq(['subjn'])
      expect(assigns(:collection).multi_page).to eq(true)
      expect(assigns(:collection).original_publisher).to eq(['opub'])
      expect(assigns(:collection).private_note).to eq(['note'])
    end
  end

  describe "#update" do
    let(:collection) { make_collection(
      @user, title: 'something', tag: ['tag'],
      abstract: ['testa'], bibliographic_citation: ['cit'],
      digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
      subject_geographic: ['geo'], subject_name: ['subjn'],
      multi_page: true, original_publisher: ['opub'],
      private_note: ['note']
    ) }

    context 'institutional collections' do
      let(:inst_col) { make_collection(
        create(:user), title: 'Inst', id: 'ic1',
        institutional_collection: true
      ) }
      let(:inst_role) { create(:role, name: 'Center1') }
      let(:inst_admin_role) { create(:role, name: 'Center1-Admin') }
      let(:inst_user) { create(:user, username: 'c1_prof') }
      let(:inst_admin) { create(:user, username: 'c1_admin') }

      describe 'unauthenticated' do
        before { sign_out @user }
        subject { patch :update, id: inst_col }

        it { is_expected.to redirect_to('/users/sign_in') }
      end

      describe 'authenticated unauthorized user' do
        before { patch :update, id: inst_col }

        specify do
          expect(response).to redirect_to('/')
          expect(flash.alert).to include('not authorized')
        end
      end

      describe 'authenticated authorized user' do
        before do
          inst_user.add_role(inst_role.name)
          inst_col.permissions.create(
            name: 'Center1', type: 'group', access: 'edit',
            access_to: inst_col.id)
          inst_col.save!
          sign_out @user
          sign_in inst_user
        end

        context 'adding members' do
          let(:gf) { make_generic_file(inst_user) }
          specify do
            expect {
              patch :update, id: inst_col,
                    :collection => { 'members' => 'add' },
                    :batch_document_ids => [gf.id]
            }.to change { inst_col.reload.member_ids.count }.by(1)
            expect(response).to redirect_to('/collections/ic1')
          end

          describe 'permission update' do
            let(:col1) { make_collection(inst_user) }

            it 'schedules add permission update jobs' do
              col_job = double('col_id')
              expect(ResolrizeGenericFileJob).to receive(
                :new).with(gf.id).and_return(col_job)
              col_job1 = double('col_id1')
              expect(ResolrizeGenericFileJob).to receive(
                :new).with(col1.id).and_return(col_job1)
              expect(Sufia.queue).to receive(:push).with(col_job)
              expect(Sufia.queue).to receive(:push).with(col_job1)
              job1 =  double('one')
              job1 =  double('one')
              expect(AddInstitutionalAdminPermissionsJob).to receive(:new).with(
                  gf.id, inst_col.id).and_return(job1)
              job2 =  double('two')
              expect(AddInstitutionalAdminPermissionsJob).to receive(:new).with(
                  col1.id, inst_col.id).and_return(job2)
              expect(Sufia.queue).to receive(:push).with(job1)
              expect(Sufia.queue).to receive(:push).with(job2)
              patch :update, id: inst_col,
                    :collection => { 'members' => 'add' },
                    :batch_document_ids => [gf.id, col1.id]
            end
          end
        end

        context 'updating non-member attributes' do
          it 'does not update the title' do
            patch :update, id: inst_col,
                  :collection => { 'title' => 'New Title' }
            expect(inst_col.reload.title).to eq('Inst')
            expect(response).to redirect_to('/collections/ic1')
          end
        end
      end

      describe 'authenticated authorized admin' do
        before do
          inst_admin.add_role(inst_admin_role.name)
          inst_col.permissions.create(
            name: 'Center1-Admin', type: 'group', access: 'edit',
            access_to: inst_col.id)
          inst_col.save!
          sign_out @user
          sign_in inst_admin
        end

        context 'removing members' do
          let(:gf) { make_generic_file(inst_admin) }
          before do
            inst_col.members << gf
            gf.save
            inst_col.save
          end

          specify do
            expect(inst_col.reload.member_ids.count).to eq(1)
            expect {
              patch :update, id: inst_col,
                    :collection => { 'members' => 'remove' },
                    :batch_document_ids => [gf.id]
            }.to change {
              inst_col.reload.member_ids.count
            }.by(-1)
          end

          describe 'removing members including an institutional one' do
            let(:inst_col_child) { make_collection(
              inst_admin, institutional_collection: true) }
            before do
              inst_col.members << inst_col_child
              inst_col.save
            end

            it 'does not allow action' do
              expect(inst_col.reload.member_ids.count).to eq(2)
              expect {
                patch :update, id: inst_col,
                      :collection => { 'members' => 'remove' },
                      :batch_document_ids => [gf.id, inst_col_child.id]
              }.not_to change { inst_col.reload.member_ids.count }
              expect(flash.alert).to include('You are not authorized')
            end
          end

          describe 'permission update' do
            let(:col1) { make_collection(inst_admin) }

            it 'schedules add permission update jobs' do
              col_job = double('col_id')
              expect(ResolrizeGenericFileJob).to receive(
                :new).with(gf.id).and_return(col_job)
              col_job1 = double('col_id1')
              expect(ResolrizeGenericFileJob).to receive(
                :new).with(col1.id).and_return(col_job1)
              expect(Sufia.queue).to receive(:push).with(col_job)
              expect(Sufia.queue).to receive(:push).with(col_job1)
              job1 =  double('one')
              expect(RemoveInstitutionalAdminPermissionsJob).to receive(
                :new).with(gf.id, inst_col.id).and_return(job1)
              job2 =  double('two')
              expect(RemoveInstitutionalAdminPermissionsJob).to receive(
                :new).with(col1.id, inst_col.id).and_return(job2)
              expect(Sufia.queue).to receive(:push).with(job1)
              expect(Sufia.queue).to receive(:push).with(job2)
              patch :update, id: inst_col,
                    :collection => { 'members' => 'remove' },
                    :batch_document_ids => [gf.id, col1.id]
            end
          end
        end

        context 'updating attributes' do
          let(:gf) { make_generic_file(inst_admin) }
          specify do
            expect {
              patch :update, id: inst_col,
                    :collection => { 'members' => 'add', title: 'New Title' },
                    :batch_document_ids => [gf.id]
            }.to change { inst_col.reload.member_ids.count }.by(1)
            expect(inst_col.reload.title).to eq('New Title')
            expect(response).to redirect_to('/collections/ic1')
          end

          describe 'permission update' do
            let(:col1) { make_collection(inst_user) }

            it 'schedules add permission update jobs' do
              col_job = double('col_id')
              expect(ResolrizeGenericFileJob).to receive(
                :new).with(gf.id).and_return(col_job)
              col_job1 = double('col_id1')
              expect(ResolrizeGenericFileJob).to receive(
                :new).with(col1.id).and_return(col_job1)
              expect(Sufia.queue).to receive(:push).with(col_job)
              expect(Sufia.queue).to receive(:push).with(col_job1)
              job1 =  double('one')
              job1 =  double('one')
              expect(AddInstitutionalAdminPermissionsJob).to receive(:new).with(
                  gf.id, inst_col.id).and_return(job1)
              job2 =  double('two')
              expect(AddInstitutionalAdminPermissionsJob).to receive(:new).with(
                  col1.id, inst_col.id).and_return(job2)
              expect(Sufia.queue).to receive(:push).with(job1)
              expect(Sufia.queue).to receive(:push).with(job2)
              patch :update, id: inst_col,
                    :collection => { 'members' => 'add' },
                    :batch_document_ids => [gf.id, col1.id]
            end
          end
        end
      end
    end

    context 'visibility' do
      it 'allows for visibility settings changes to more restrictive' do
        patch(
          :update,
          id: collection,
          collection: {},
          visibility: 'restricted'
        )
        expect(collection.reload.visibility).to eq('restricted')
      end

      it 'allows for visibility settings changes to less restrictive' do
        collection.visibility = 'restricted'
        collection.save!
        patch(
          :update,
          id: collection,
          collection: {},
          visibility: 'authenticated'
        )
        expect(collection.reload.visibility).to eq('authenticated')
      end

      it 'disallows for visibility settings changes to an unexpected value' do
        expect {
          patch(
            :update,
            id: collection,
            visibility: 'bogus'
          )
        }.to raise_exception { ArgumentError }
      end
    end

    context 'permissions' do
      describe 'converts generic_file permissions_attributes to collection' do
        context 'non-empty params["collection"]["permissions_attributes"]' do
          it 'merges the permissions_attributes' do
            patch(
              :update,
              id: collection,
              collection: {
                permissions_attributes: {
                  '7' => {
                    'type' => 'user', 'name' => 'from_col', 'access'=>'read'
                  }
                }
              }, generic_file: {
                permissions_attributes: {
                  '5' => {
                    'type' => 'user', 'name' => 'from_gen', 'access'=>'read'
                  }
                }
              }
            )

            expect(
              controller.params['collection']['permissions_attributes']['7']
            ).to be_present
            expect(
              controller.params['collection']['permissions_attributes']['5']
            ).to be_present

            expect(
              collection.reload.permissions.map(&:agent_name)
            ).to include('from_col')
            expect(
              collection.reload.permissions.map(&:agent_name)
            ).to include('from_gen')
          end
        end

        context 'empty params["collection"]["permissions_attributes"]' do
          it 'populates the permissions_attributes' do
            patch(
              :update,
              id: collection,
              generic_file: {
                permissions_attributes: {
                  '5' => {
                    'type' => 'user', 'name' => 'from_gen', 'access'=>'read'
                  }
                }
              }
            )

            expect(
              controller.params['collection']['permissions_attributes']['5']
            ).to be_present

            expect(
              collection.reload.permissions.map(&:agent_name)
            ).to include('from_gen')
          end
        end

        it 'can delete an existing permission' do
          collection.permissions_attributes = {
            '5' => {
              'type' => 'user', 'name' => 'goodguy', 'access' => 'read'
            }
          }
          collection.save!

          pid = collection.reload.permissions.to_a.find {|o|
            o.agent_name == 'goodguy' }.id

          patch(
            :update,
            id: collection,
            collection: {
              permissions_attributes: { '5' => { 'id' => pid, 'access'=>'read' } }
            },
            generic_file: {
              permissions_attributes: { '5' => { '_destroy' => 'true' } }
            }
          )

          expect(
            collection.reload.permissions.map(&:agent_name)
          ).not_to include('goodguy')
        end

        it 'can update an existing permission' do
          collection.permissions_attributes = {
            '5' => {
              'type' => 'user', 'name' => 'goodguy', 'access' => 'read'
            }
          }
          collection.save!

          permission = collection.reload.permissions.to_a.find {|o|
            o.agent_name == 'goodguy' }
          expect(permission.access).to eq('read')

          patch(
            :update,
            id: collection,
            collection: {
              permissions_attributes: {
                '5' => { 'id' => permission.id, 'access'=>'edit' }
              }
            },
          )

          # permission.reload.access doesn't work, hece this
          expect(
            collection.reload.permissions.to_a.find {|o|
              o.agent_name == 'goodguy'
            }.access
          ).to eq('edit')
        end
      end
    end

    it "should update abstract" do
      patch :update, id: collection, collection: { abstract: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).abstract).to eq(['dudu'])
    end

    it "should update bibliographic_citation" do
      patch :update, id: collection, collection: {
        bibliographic_citation: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).bibliographic_citation).to eq(['dudu'])
    end

    it "should update subject_name" do
      patch :update, id: collection, collection: { subject_name: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).subject_name).to eq(['dudu'])
    end

    it "should update subject_geographic" do
      patch :update, id: collection, collection: { subject_geographic: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).subject_geographic).to eq(['dudu'])
    end

    it "should update mesh" do
      patch :update, id: collection, collection: { mesh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).mesh).to eq(['dudu'])
    end

    it "should update lcsh" do
      patch :update, id: collection, collection: { lcsh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).lcsh).to eq(['dudu'])
    end

    it "should not allow to update digital_origin" do
      patch :update, id: collection, collection: { digital_origin: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).digital_origin).to eq(['digo'])
    end

    it "should update multi_page" do
      patch :update, id: collection, collection: { multi_page: false }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).multi_page).to eq(false)
    end

    it "should update original_publisher" do
      patch :update, id: collection, collection: { original_publisher: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).original_publisher).to eq(['dudu'])
    end

    it "should update private_note" do
      patch :update, id: collection, collection: { private_note: ['no note'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(collection))
      expect(assigns(:collection).private_note).to eq(['no note'])
    end
  end

  describe '#follow' do
    let(:collection) { make_collection(create(:user)) }
    subject { post :follow, id: collection.id }

    context 'follow is successful' do
      specify do
        expect(subject).to redirect_to("/collections/#{collection.id}")
        expect(collection.followers).to include(@user.id)
        expect(flash.notice).to include("follow #{collection.title}")
      end
    end

    context 'follow is not successful' do
      before do
        expect_any_instance_of(Collection).to receive(:follow).and_return(false)
      end

      specify do
        expect(subject).to redirect_to("/collections/#{collection.id}")
        expect(collection.followers).not_to include(@user.id)
        expect(flash.alert).to include("There was a problem")
      end
    end
  end

  describe '#unfollow' do
    let(:collection) { make_collection(create(:user)) }
    subject { post :unfollow, id: collection.id }

    context 'unfollow is successful' do
      before do
        collection.follow(@user)
      end

      specify do
        expect(subject).to redirect_to("/collections/#{collection.id}")
        expect(collection.followers).not_to include(@user.id)
        expect(flash.notice).to include("stopped following #{collection.title}")
      end
    end

    context 'follow is not successful' do
      specify do
        expect(subject).to redirect_to("/collections/#{collection.id}")
        expect(flash.alert).to include("There was a problem")
      end
    end
  end
end
