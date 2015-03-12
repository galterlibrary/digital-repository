require 'rails_helper'

describe GenericFilesController do
  before do
    @user = FactoryGirl.create(:user)
    sign_in @user
    @routes = Sufia::Engine.routes
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

  describe "#create" do
    before do
      @mock_upload_directory = 'spec/mock_upload_directory'
      Dir.mkdir @mock_upload_directory unless File.exists? @mock_upload_directory
      FileUtils.copy('spec/fixtures/system.png', @mock_upload_directory)
    end

    after do
      expect_any_instance_of(FileContentDatastream).to receive(:live?).and_return(true)
    end

    it "should ingest files from the filesystem" do
      pending "Figure out how to tests file-update"
      expect(
        post :create, local_file: ["system.png"], batch_id: "xw42n7934"
      ).to change(GenericFile, :count).by(1)

    end
  end

  describe "#update" do
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

    it "should update abstract" do
      patch :update, id: @file, generic_file: { abstract: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.edit_generic_file_path(@file))
      expect(assigns(:generic_file).abstract).to eq(['dudu'])
    end

    it "should update bibliographic_citation" do
      patch :update, id: @file, generic_file: {
        bibliographic_citation: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.edit_generic_file_path(@file))
      expect(assigns(:generic_file).bibliographic_citation).to eq(['dudu'])
    end

    it "should update subject_name" do
      patch :update, id: @file, generic_file: { subject_name: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.edit_generic_file_path(@file))
      expect(assigns(:generic_file).subject_name).to eq(['dudu'])
    end

    it "should update subject_geographic" do
      patch :update, id: @file, generic_file: { subject_geographic: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.edit_generic_file_path(@file))
      expect(assigns(:generic_file).subject_geographic).to eq(['dudu'])
    end

    it "should update mesh" do
      patch :update, id: @file, generic_file: { mesh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.edit_generic_file_path(@file))
      expect(assigns(:generic_file).mesh).to eq(['dudu'])
    end

    it "should update lcsh" do
      patch :update, id: @file, generic_file: { lcsh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.edit_generic_file_path(@file))
      expect(assigns(:generic_file).lcsh).to eq(['dudu'])
    end

    it "should update digital_origin" do
      patch :update, id: @file, generic_file: { digital_origin: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.edit_generic_file_path(@file))
      expect(assigns(:generic_file).digital_origin).to eq(['dudu'])
    end

    it "should update page_number" do
      patch :update, id: @file, generic_file: { page_number: 22 }
      expect(response).to redirect_to(
        @routes.url_helpers.edit_generic_file_path(@file))
      expect(assigns(:generic_file).page_number).to eq('22')
    end
  end
end
