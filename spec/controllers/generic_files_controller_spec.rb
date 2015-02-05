require 'rails_helper'

describe GenericFilesController do
  before do
    @user = FactoryGirl.create(:user)
    sign_in @user
    @routes = Sufia::Engine.routes
     GenericFile.delete_all
  end

  after do
    GenericFile.delete_all
  end

  describe "#show" do
    before do
      @file = GenericFile.new(abstract: ['testa'])
      @file.apply_depositor_metadata(@user.user_key)
      @file.save!
    end

    it "should show xml" do
      get :show, id: @file
      expect(response).to be_successful
      expect(assigns(:generic_file).abstract).to eq(['testa'])
    end
  end

  describe "#create" do
    before do
      @mock_upload_directory = 'spec/mock_upload_directory'
      Dir.mkdir @mock_upload_directory unless File.exists? @mock_upload_directory
      FileUtils.copy('spec/fixtures/system.png', @mock_upload_directory)
    end

    after do
      FileContentDatastream.any_instance.stub(:live?).and_return(true)
      GenericFile.destroy_all
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
      @file = GenericFile.new(abstract: ['testa'])
      @file.apply_depositor_metadata(@user.user_key)
      @file.save!
    end

    it "should update abstract" do
      patch :update, id: @file, generic_file: { abstract: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.edit_generic_file_path(@file))
      expect(assigns(:generic_file).abstract).to eq(['dudu'])
    end
  end
end
