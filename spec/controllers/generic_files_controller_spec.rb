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
        page_number: 11, acknowledgments: ['ack'],
        grants_and_funding: ['gaf']
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
      expect(assigns(:generic_file).acknowledgments).to eq(['ack'])
      expect(assigns(:generic_file).grants_and_funding).to eq(['gaf'])
    end

    context 'generic file is of type Page' do
      before do
        make_page(@user, id: 'p1', title: ['Page1'])
        get :show, id: 'p1'
      end

      it 'assigns the page to @generic_file' do
        expect(assigns(:generic_file)).to be_an_instance_of(Page)
        expect(assigns(:generic_file).title).to eq(['Page1'])
      end

      it 'prevents search bots from indexing' do
        expect(response.headers['X-Robots-Tag']).to eq('noindex')
      end
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
          file, 'system.png', 'content', 'image/png', nil).and_return(true)
      allow_any_instance_of(Nuldap).to receive(
        :search).and_return([true, {
          'mail' => ['a@b.c'],
          'sn' => ['Name'],
          'givenName' => ['Formal']
        }])
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
        resource_type: ['restype'], rights: ['rights'], title: ['title'],
        doi: ['doi1', 'doi2', 'doi3']
      )
      @file.apply_depositor_metadata(@user.user_key)
      @file.save!
    end

    describe 'doi job scheduling' do
      before do
        job =  double('two')
        allow(ContentUpdateEventJob).to receive(:new).and_return(job)
        allow(Sufia.queue).to receive(:push).with(job)
      end

      context 'deactivation job' do
        before do
          job =  double('mint')
          allow(MintDoiJob).to receive(:new).and_return(job)
          allow(Sufia.queue).to receive(:push).with(job)
        end

        describe 'dois are replaced' do
          it 'schedules the job' do
            job1 =  double('one')
            job2 =  double('two')
            expect(DeactivateDoiJob).to receive(:new).with(
              @file.id, 'doi2', @user.username, 'title').and_return(job1)
            expect(DeactivateDoiJob).to receive(:new).with(
              @file.id, 'doi3', @user.username, 'title').and_return(job2)
            expect(Sufia.queue).to receive(:push).with(job1)
            expect(Sufia.queue).to receive(:push).with(job2)
            patch :update,
                  :id => @file.id,
                  :generic_file => { doi: ['doi1', 'doi4', 'doi5', ''] }
          end
        end

        describe 'dois are removed' do
          it 'schedules the job' do
            job1 =  double('one')
            job2 =  double('two')
            expect(DeactivateDoiJob).to receive(:new).with(
              @file.id, 'doi1', @user.username, 'title').and_return(job1)
            expect(DeactivateDoiJob).to receive(:new).with(
              @file.id, 'doi2', @user.username, 'title').and_return(job2)
            expect(Sufia.queue).to receive(:push).with(job1)
            expect(Sufia.queue).to receive(:push).with(job2)
            patch :update,
                  :id => @file.id,
                  :generic_file => { doi: ['doi3', ''] }
          end
        end

        describe 'new dois are added' do
          it 'does not schedule the job' do
            expect(DeactivateDoiJob).not_to receive(:new)
            patch :update,
                  :id => @file.id,
                  :generic_file => { doi: ['doi1', 'doi2', 'doi3', 'doi4'] }
          end
        end

        describe 'dois are not changed' do
          it 'does not schedule the job' do
            expect(DeactivateDoiJob).not_to receive(:new)
            patch :update,
                  :id => @file.id,
                  :generic_file => { doi: ['doi1', 'doi2', 'doi3', ''] }
          end
        end
      end

      context 'minting job' do
        it 'schedules the job' do
          job1 =  double('one')
          expect(MintDoiJob).to receive(:new).with(
            @file.id, @user.username).and_return(job1)
          expect(Sufia.queue).to receive(:push).with(job1)
          patch :update, id: @file, generic_file: { abstract: ['dudu'] }
        end
      end
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

    it "should update acknowledgments" do
      patch :update, id: @file, generic_file: { acknowledgments: ['ack2'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).acknowledgments).to eq(['ack2'])
    end

    it "should update grants_and_funding" do
      patch :update, id: @file, generic_file: { grants_and_funding: ['gaf2'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).grants_and_funding).to eq(['gaf2'])
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

    it "should update doi" do
      expect(@file.doi).to match_array(['doi1', 'doi2', 'doi3'])
      patch :update, id: @file, generic_file: { doi: ['doi'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).doi).to eq(['doi'])
    end

    it "should update ark" do
      expect(@file.ark).to be_blank
      patch :update, id: @file, generic_file: { ark: ['ark'] }
      expect(response).to redirect_to(
        @routes.url_helpers.generic_file_path(@file))
      expect(assigns(:generic_file).ark).to eq(['ark'])
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

  describe "#destroy" do
    let(:admin_user) { create(:admin_user, username: 'admin') }
    before { sign_in admin_user }

    describe 'doi deactivation job scheduling' do
      before do
        job =  double('job')
        expect(ContentDeleteEventJob).to receive(:new).and_return(job)
        expect(Sufia.queue).to receive(:push).with(job)
      end

      describe 'file containing DOIs' do
        let(:file) { make_generic_file(
          admin_user, title: ['Some Title'], doi: ['doi1', 'doi2'],
          id: 'will_die'
        ) }

        it 'schedules the jobs' do
          job1 =  double('one')
          job2 =  double('two')
          expect(DeactivateDoiJob).to receive(:new).with(
            'will_die', 'doi1', 'admin', 'Some Title').and_return(job1)
          expect(DeactivateDoiJob).to receive(:new).with(
            'will_die', 'doi2', 'admin', 'Some Title').and_return(job2)
          expect(Sufia.queue).to receive(:push).with(job1)
          expect(Sufia.queue).to receive(:push).with(job2)
          delete :destroy, :id => file.id
        end
      end

      describe 'file not containing DOIs' do
        let(:file) { make_generic_file(
          admin_user, title: ['Some Title'], doi: [], id: 'will_die'
        ) }

        it 'schedules the jobs' do
          expect(DeactivateDoiJob).not_to receive(:new)
          delete :destroy, :id => file.id
        end
      end
    end
  end
end
