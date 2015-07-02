require 'rails_helper'

describe Riiif::ImagesController do
  let(:png_image) { open(File.expand_path('spec/fixtures/system.png')) }
  routes { Riiif::Engine.routes }

  describe '#show' do
    let(:user) { create(:user, username: 'abc') }
    let(:user_file) { make_generic_file(user, id: 'ufile', visibility: 'restricted') }
    before do
      user_file.add_file(png_image, path: 'content')
      user_file.save
    end

    context 'user unauthorized to read the file in Fedora' do
      it 'allows access to the file' do
        expect(
          get :show, {
            id: 'ufile', region: 'full', size: 'full',
            rotation: '0', quality: 'native', format: 'png'
          }
        ).to redirect_to('/users/sign_in')
        expect(response.status).to eq(302)
      end
    end

    context 'user authorized to read the file in Fedora' do
      it 'denies access to the file' do
        sign_in(user)
        get :show, {
          id: 'ufile', region: 'full', size: 'full',
          rotation: '0', quality: 'native', format: 'png'
        }
        expect(response.status).to eq(200)
        expect(response.header['Content-Type']).to eq('image/png')
        expect(response.body.encoding.to_s).to eq('ASCII-8BIT')
        expect(response.body.bytesize).to eq(1459)
      end
    end
  end

  describe '#info' do
    let(:user) { create(:user, username: 'abc') }
    let(:user_file) { make_generic_file(user, id: 'ufile', visibility: 'restricted') }
    before do
      user_file.characterization.width = ['200']
      user_file.characterization.height = ['100']
      user_file.save
    end

    context 'user unauthorized to read the file in Fedora' do
      it 'denies access to the file' do
        expect(
          get :info, { id: 'ufile', format: 'json' }
        ).to redirect_to('/users/sign_in')
        expect(response.status).to eq(302)
      end
    end

    context 'user authorized to read the file in Fedora' do
      it 'allows access to the file' do
        sign_in(user)
        get :info, { id: 'ufile', format: 'json' }
        expect(response.status).to eq(200)
        expect(response.header['Content-Type']).to match('application/json')
        expect(response.body.encoding.to_s).to eq('UTF-8')
        expect(JSON.parse(response.body)['height']).to eq(100)
        expect(JSON.parse(response.body)['width']).to eq(200)
      end
    end
  end
end
