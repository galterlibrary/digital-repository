require 'rails_helper'
require 'iiif/presentation'

RSpec.describe IiifApisController, :type => :controller do

  describe "GET manifest" do
    it "returns http success" do
      get :manifest, { id: '1234' }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET sequence" do
    it "returns http success" do
      get :sequence, { id: '1234', name: 'blah' }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET canvas" do
    describe '#canvas' do
      let(:user) { FactoryGirl.create(:user) }

      before do
        @generic_file = GenericFile.new(id: 'testa')
        @generic_file.apply_depositor_metadata(user.user_key)
        @generic_file.save!
      end

      subject { get :canvas, { id: 'testa', name: 'blah' } }

      it { is_expected.to have_http_status(:success) }

      it "returns IIIF annotation json" do
        expect(subject.body).to eq(
          '{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"/iiif-api/generic_file/testa/canvas/blah","@type":"sc:Canvas","label":"blah","height":0,"width":0,"images":[{"@id":"/iiif-api/generic_file/testa/annotation/blah","@type":"oa:Annotation","on":"/iiif-api/generic_file/testa/canvas/blah","motivation":"sc:painting","resource":[{"@id":"/image-service/testa/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0}]}]}')
      end
    end

    describe '#generate_canvas' do
      let(:generic_file) { GenericFile.new(id: 'testa') }
      subject { controller.send(:generate_canvas, generic_file, 'p33') }

      it { is_expected.to be_an_instance_of(IIIF::Presentation::Canvas) }

      it 'generates correct type' do
        expect(subject['@type']).to eq('sc:Canvas')
      end

      it 'generates correct label' do
        expect(subject['label']).to eq('p33')
      end

      it 'generates correct images' do
        expect(subject['images'].first).to be_an_instance_of(
          IIIF::Presentation::Annotation)
        expect(subject['images'].first['@id']).to eq(
          '/iiif-api/generic_file/testa/annotation/p33')
      end

      context 'passed name' do
        it 'generates correct canvas path' do
          expect(subject['@id']).to eq(
            '/iiif-api/generic_file/testa/canvas/p33')
        end
      end

      context 'derived name' do
        before do
          generic_file.page_number = 33
        end

        subject { controller.send(:generate_canvas, generic_file) }

        it 'generates correct canvas path' do
          expect(subject['@id']).to eq(
            '/iiif-api/generic_file/testa/canvas/p33')
        end
      end

      it 'generates correct height' do
        allow(generic_file).to receive(:height).and_return(['20'])
        expect(subject['height']).to eq(20)
      end

      it 'generates correct width' do
        allow(generic_file).to receive(:width).and_return(['50'])
        expect(subject['width']).to eq(50)
      end
    end
  end

  describe "GET annotation" do
    describe '#annotation' do
      let(:user) { FactoryGirl.create(:user) }

      before do
        @generic_file = GenericFile.new(id: 'testa')
        @generic_file.apply_depositor_metadata(user.user_key)
        @generic_file.save!
      end

      subject { get :annotation, { id: 'testa', name: 'blah' } }

      it { is_expected.to have_http_status(:success) }

      it "returns IIIF annotation json" do
        expect(subject.body).to eq(
          '{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"/iiif-api/generic_file/testa/annotation/blah","@type":"oa:Annotation","on":"/iiif-api/generic_file/testa/canvas/blah","motivation":"sc:painting","resource":[{"@id":"/image-service/testa/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0}]}')
      end
    end

    describe '#generate_annotation' do
      before do
        @generic_file = GenericFile.new(id: 'testa')
      end

      subject { controller.send(:generate_annotation, @generic_file, 'p33') }

      it { is_expected.to be_an_instance_of(IIIF::Presentation::Annotation) }

      it 'generates correct type' do
        expect(subject['@type']).to eq('oa:Annotation')
      end

      it 'generates correct motivation' do
        expect(subject['motivation']).to eq('sc:painting')
      end

      it 'generates correct resource' do
        expect(subject['resource'].first).to be_an_instance_of(
          IIIF::Presentation::ImageResource)
      end

      context 'passed name' do
        it 'generates correct annotation path' do
          expect(subject['@id']).to eq(
            '/iiif-api/generic_file/testa/annotation/p33')
        end

        it 'generates correct on canvas path' do
          expect(subject['on']).to eq('/iiif-api/generic_file/testa/canvas/p33')
        end
      end

      context 'derived name' do
        before do
          @generic_file.page_number = 33
        end

        subject { controller.send(:generate_annotation, @generic_file) }
        it 'generates correct annotation path' do
          expect(subject['@id']).to eq(
            '/iiif-api/generic_file/testa/annotation/p33')
        end

        it 'generates correct on canvas path' do
          expect(subject['on']).to eq('/iiif-api/generic_file/testa/canvas/p33')
        end
      end
    end
  end

  describe "GET list" do
    it "returns http success" do
      get :list, { id: '1234', name: 'blah' }
      expect(response).to have_http_status(:success)
    end
  end
end
