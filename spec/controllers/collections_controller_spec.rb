require 'rails_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  before do
    @user = FactoryGirl.create(:user, username: 'badmofo')
    sign_in @user
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
        multi_page: true
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
    end
  end

  describe "#create" do
    it 'creates collection' do
      expect {
        post :create, id: @collection, collection: {
          title: 'something', description: 'desc', tag: ['tag'],
          abstract: ['testa'], bibliographic_citation: ['cit'],
          digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
          subject_geographic: ['geo'], subject_name: ['subjn']
        }
      }.to change { Collection.count }.by(1)
    end

    it 'populates the custom attributes' do
      post :create, id: @collection, collection: {
        title: 'something', description: 'desc', tag: ['tag'],
        abstract: ['testa'], bibliographic_citation: ['cit'],
        digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
        subject_geographic: ['geo'], subject_name: ['subjn'],
        multi_page: 'true'
      }
      expect(assigns(:collection).abstract).to eq(['testa'])
      expect(assigns(:collection).bibliographic_citation).to eq(['cit'])
      expect(assigns(:collection).digital_origin).to be_blank
      expect(assigns(:collection).mesh).to eq(['mesh'])
      expect(assigns(:collection).lcsh).to eq(['lcsh'])
      expect(assigns(:collection).subject_geographic).to eq(['geo'])
      expect(assigns(:collection).subject_name).to eq(['subjn'])
      expect(assigns(:collection).multi_page).to eq(true)
    end
  end

  describe "#update" do
    before do
      @collection = make_collection(
        @user, title: 'something', tag: ['tag'],
        abstract: ['testa'], bibliographic_citation: ['cit'],
        digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
        subject_geographic: ['geo'], subject_name: ['subjn'],
        multi_page: true
      )
    end

    context 'visibility' do
      it 'allows for visibility settings changes to more restrictive' do
        patch(
          :update,
          id: @collection,
          collection: {},
          visibility: 'restricted'
        )
        expect(@collection.reload.visibility).to eq('restricted')
      end

      it 'allows for visibility settings changes to less restrictive' do
        @collection.visibility = 'restricted'
        @collection.save!
        patch(
          :update,
          id: @collection,
          collection: {},
          visibility: 'authenticated'
        )
        expect(@collection.reload.visibility).to eq('authenticated')
      end

      it 'disallows for visibility settings changes to an unexpected value' do
        expect {
          patch(
            :update,
            id: @collection,
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
              id: @collection,
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
              @collection.reload.permissions.map(&:agent_name)
            ).to include('from_col')
            expect(
              @collection.reload.permissions.map(&:agent_name)
            ).to include('from_gen')
          end
        end

        context 'empty params["collection"]["permissions_attributes"]' do
          it 'populates the permissions_attributes' do
            patch(
              :update,
              id: @collection,
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
              @collection.reload.permissions.map(&:agent_name)
            ).to include('from_gen')
          end
        end

        it 'can delete an existing permission' do
          @collection.permissions_attributes = {
            '5' => {
              'type' => 'user', 'name' => 'goodguy', 'access' => 'read'
            }
          }
          @collection.save!

          pid = @collection.reload.permissions.to_a.find {|o|
            o.agent_name == 'goodguy' }.id

          patch(
            :update,
            id: @collection,
            collection: {
              permissions_attributes: { '5' => { 'id' => pid, 'access'=>'read' } }
            },
            generic_file: {
              permissions_attributes: { '5' => { '_destroy' => 'true' } }
            }
          )

          expect(
            @collection.reload.permissions.map(&:agent_name)
          ).not_to include('goodguy')
        end

        it 'can update an existing permission' do
          @collection.permissions_attributes = {
            '5' => {
              'type' => 'user', 'name' => 'goodguy', 'access' => 'read'
            }
          }
          @collection.save!

          permission = @collection.reload.permissions.to_a.find {|o|
            o.agent_name == 'goodguy' }
          expect(permission.access).to eq('read')

          patch(
            :update,
            id: @collection,
            collection: {
              permissions_attributes: {
                '5' => { 'id' => permission.id, 'access'=>'edit' }
              }
            },
          )

          # permission.reload.access doesn't work, hece this
          expect(
            @collection.reload.permissions.to_a.find {|o|
              o.agent_name == 'goodguy'
            }.access
          ).to eq('edit')
        end
      end
    end

    it "should update abstract" do
      patch :update, id: @collection, collection: { abstract: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).abstract).to eq(['dudu'])
    end

    it "should update bibliographic_citation" do
      patch :update, id: @collection, collection: {
        bibliographic_citation: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).bibliographic_citation).to eq(['dudu'])
    end

    it "should update subject_name" do
      patch :update, id: @collection, collection: { subject_name: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).subject_name).to eq(['dudu'])
    end

    it "should update subject_geographic" do
      patch :update, id: @collection, collection: { subject_geographic: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).subject_geographic).to eq(['dudu'])
    end

    it "should update mesh" do
      patch :update, id: @collection, collection: { mesh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).mesh).to eq(['dudu'])
    end

    it "should update lcsh" do
      patch :update, id: @collection, collection: { lcsh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).lcsh).to eq(['dudu'])
    end

    it "should not allow to update digital_origin" do
      patch :update, id: @collection, collection: { digital_origin: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).digital_origin).to eq(['digo'])
    end

    it "should update multi_page" do
      patch :update, id: @collection, collection: { multi_page: false }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).multi_page).to eq(false)
    end
  end
end
