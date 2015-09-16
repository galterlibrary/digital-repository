require 'rails_helper'

describe PagesController do
  describe '#show' do
    it 'allows help_page id' do
      expect(
        get :show, id: 'help_page'
      ).to render_template('pages/tiny_mce_page')
    end

    it 'allows terms_page id' do
      expect(
        get :show, id: 'terms_page'
      ).to render_template('pages/tiny_mce_page')
    end

    it 'allows agreement_page id' do
      expect(
        get :show, id: 'agreement_page'
      ).to render_template('pages/tiny_mce_page')
    end

    it 'allows news_page id' do
      expect(
        get :show, id: 'news_page'
      ).to render_template('pages/tiny_mce_page')
    end

    describe 'sufia routes' do
      routes { Sufia::Engine.routes }

      it 'allows about_page id' do
        expect(
          get :show, id: 'about_page'
        ).to render_template('pages/tiny_mce_page')
      end
    end

    it 'disallows any other id' do
      expect{
        get :show, id: rand(36**10).to_s(36)
      }.to raise_error(ActionController::UrlGenerationError)
    end

    context 'ContentBlock does not exist' do
      it 'creates a new instance of ContentBlock' do
        get :show, id: 'news_page'
        expect(assigns(:page)).to be_an_instance_of(ContentBlock)
        expect(assigns(:page).id).to be_present
      end
    end

    context 'ContentBlock exists' do
      it 'uses the existing instance of ContentBlock' do
        cb = ContentBlock.create(name: 'news_page')
        get :show, id: 'news_page'
        expect(assigns(:page)).to eq(cb)
      end
    end
  end
end
