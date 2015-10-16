require 'rails_helper'

describe GenericFilesController do
  before do
    @user = FactoryGirl.create(:user)
    sign_in @user
    @routes = Sufia::Engine.routes
  end

  describe "#destroy" do
    before do
      @file = make_generic_file(@user, id: 'nukeme')
    end

    it 'does not allow non-admin owner to delete files' do
      expect {
        delete :destroy, id: 'nukeme'
      }.not_to change(GenericFile, :count)
      expect(flash[:alert]).to match('You are not authorized')
    end

    it 'allows an admin user to delete files' do
      @user = FactoryGirl.create(:user)
      @user.add_role(Role.create(name: 'admin').name)
      sign_in @user

      expect {
        delete :destroy, id: 'nukeme'
      }.to change(GenericFile, :count).by(-1)
      expect { GenericFile.find('nukeme') }.to raise_error(Ldp::Gone)
    end
  end

  describe "#show" do
    before do
      @file = GenericFile.new(
        abstract: ['testa'], bibliographic_citation: ['cit'],
        digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
        subject_geographic: ['geo'], subject_name: ['subjn'],
        page_number: 11
      )
      @file.apply_depositor_metadata(@user.user_key)
      @file.save!
    end

    it "should assign proper generic_file" do
      get :show, id: @file
      expect(response).to be_successful
      expect(assigns(:generic_file).abstract).to eq(['testa'])
      expect(assigns(:generic_file).bibliographic_citation).to eq(['cit'])
      expect(assigns(:generic_file).digital_origin).to eq(['digo'])
      expect(assigns(:generic_file).mesh).to eq(['mesh'])
      expect(assigns(:generic_file).lcsh).to eq(['lcsh'])
      expect(assigns(:generic_file).subject_geographic).to eq(['geo'])
      expect(assigns(:generic_file).subject_name).to eq(['subjn'])
      expect(assigns(:generic_file).page_number).to eq(11)
    end
  end

  describe '#create' do
    let(:user) { create(:user, display_name: 'Display Name',
                        :formal_name => 'Name, Formal') }
    let(:mock) { GenericFile.new(id: 'test123') }
    let(:batch) { Batch.create }
    let(:batch_id) { batch.id }
    let(:file) { fixture_file_upload('/system.png', 'image/png') }

    before do
      allow(GenericFile).to receive(:new).and_return(mock)
      expect_any_instance_of(Sufia::GenericFile::Actor).to receive(
        :create_content).with(
          file, 'system.png', 'content', 'image/png').and_return(true)
      sign_in user
    end

    it 'sets creator to formal_name of the depositor' do
      post :create, files: [file], 'Filename' => 'The system',
           :batch_id => batch_id, permission: { group: { public: 'read' } },
           :terms_of_service => '1'
      expect(assigns(:generic_file).creator).to eq(['Name, Formal'])
    end
  end

  describe "#update" do
    before do
      @file = GenericFile.new(
        abstract: ['testa'], bibliographic_citation: ['cit'],
        digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
        subject_geographic: ['geo'], subject_name: ['subjn'],
        page_number: 11, creator: ['ABC'], tag: ['tag'],
        resource_type: ['restype'], rights: ['rights'], title: ['title']
      )
      @file.apply_depositor_metadata(@user.user_key)
      @file.save!
    end

    it "should update abstract" do
      patch :update, id: @file, generic_file: { abstract: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).abstract).to eq(['dudu'])
    end

    it "should update bibliographic_citation" do
      patch :update, id: @file, generic_file: {
        bibliographic_citation: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).bibliographic_citation).to eq(['dudu'])
    end

    it "should update subject_name" do
      patch :update, id: @file, generic_file: { subject_name: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).subject_name).to eq(['dudu'])
    end

    it "should update subject_geographic" do
      patch :update, id: @file, generic_file: { subject_geographic: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).subject_geographic).to eq(['dudu'])
    end

    it "should update mesh" do
      patch :update, id: @file, generic_file: { mesh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).mesh).to eq(['dudu'])
    end

    it "should update lcsh" do
      patch :update, id: @file, generic_file: { lcsh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).lcsh).to eq(['dudu'])
    end

    it "should not allow to update digital_origin" do
      patch :update, id: @file, generic_file: { digital_origin: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).digital_origin).to eq(['digo'])
    end

    it "should update page_number" do
      patch :update, id: @file, generic_file: { page_number: 22 }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).page_number).to eq('22')
    end

    context 'visibility' do
      it 'allows for visibility settings changes to more restrictive' do
        @file.visibility = 'restricted'
        @file.save!
        patch(
          :update,
          id: @file,
          visibility: 'restricted'
        )
        expect(@file.reload.visibility).to eq('restricted')
      end

      it 'allows for visibility settings changes to less restrictive' do
        expect(@file.visibility).to eq('restricted')
        patch(
          :update,
          id: @file,
          visibility: 'authenticated'
        )
        expect(@file.reload.visibility).to eq('authenticated')
      end

      it 'disallows for visibility settings changes to an unexpected value' do
        expect {
          patch(
            :update,
            id: @file,
            visibility: 'bogus'
          )
        }.to raise_exception { ArgumentError }
      end

      it 'disallows for visibility settings changes for file with blank required fields' do
        bad_file = make_generic_file(
          @user, id: 'badfile', title: ["I'm bad"], visibility: 'restricted')
        expect(
          patch(
            :update,
            id: bad_file,
            visibility: 'open'
          )
        ).to redirect_to('/files/badfile/edit')
        expect(flash['alert']).to include(
          'Please fill out the required fields before changing the visibility')
        expect(bad_file.reload.visibility).to eq('restricted')
      end
    end
  end
end
