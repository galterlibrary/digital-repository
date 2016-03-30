require 'rails_helper'

describe DownloadsController do
  let(:png_image) { open(File.expand_path('spec/fixtures/system.png')) }
  let(:user) { create(:user) }
  before do
    @routes = Sufia::Engine.routes
  end

  describe '#show' do
    let(:gf1) { make_generic_file(
      user, title: ['abc'], id: 'gf1', visibility: 'open') }

    before do
      expect(controller).to receive(:authorize_download!).and_return(
        true)
      gf1.add_file(png_image, path: 'content')
      gf1.save!
    end

    it 'does not allow caching' do
      get :show, id: gf1.id
      expect(response.headers['Cache-Control']).to eq(
        'no-cache, no-store, max-age=0, must-revalidate')
      expect(response.headers['Pragma']).to eq('no-cache')
      expect(response.headers['Expires']).to eq(
        'Fri, 01 Jan 1990 00:00:00 GMT')
    end
  end
end
