require 'rails_helper'

describe DownloadsController do
  let(:png_image) { open(File.expand_path('spec/fixtures/system.png')) }
  let(:user) { create(:user) }
  before do
    @routes = Sufia::Engine.routes
  end

  describe '#show' do
    let(:gf1) {
      GenericFile.create do |f|
        f.apply_depositor_metadata(user.user_key)
        f.label = 'system.png'
        f.add_file(
          File.open('spec/fixtures/system.png'),
          path: 'content',
          original_name: 'system.png',
          mime_type: 'image/png'
        )
      end
    }

    before do
      sign_in user
      allow(controller).to receive(:render)
    end

    it 'uses modified_date to deterime the Last-Modified header' do
      get :show, id: gf1.id
      expect(response.code).to eq('200')
      last_mod_header = response.headers["Last-Modified"]
      expect_any_instance_of(GenericFile).to receive(:modified_date).and_return(
        gf1.modified_date + 1.hour)
      get :show, id: gf1.id
      expect(response.code).to eq('200')
      expect(response.headers["Last-Modified"]).not_to eq(last_mod_header)
    end

    it 'returns appropriate file name' do
      get :show, id: gf1.id
      expect(response.code).to eq('200')
      expect(response.header['Content-Disposition']).to include('system.png')
      expect_any_instance_of(FileContentDatastream).to receive(
        :original_name).and_return('new_file.png')
      get :show, id: gf1.id
      expect(response.code).to eq('200')
      expect(response.header['Content-Disposition']).to include('new_file.png')
    end
  end
end
