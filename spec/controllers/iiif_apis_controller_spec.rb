require 'rails_helper'
require 'iiif/presentation'

RSpec.describe IiifApisController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }

  describe "GET manifest" do
    let(:collection) { Collection.new(
      id: 'col1', title: 'something', description: 'blahbalh',
      rights: ['http://creativecommons.org/publicdomain/mark/1.0/'],
      abstract: ['abs'], mesh: ['bcd', 'efg']
    ) }

    let(:col_parent) { make_collection(user, { id: 'col_parent' }) }

    describe '#manifest' do
      before do
        collection.apply_depositor_metadata(user.user_key)
        (1..3).each do |nr|
          generic_file = GenericFile.new(id: "testa#{nr}", page_number: nr)
          generic_file.apply_depositor_metadata(user.user_key)
          generic_file.save!
          collection.members << generic_file
        end
        collection.parent = col_parent
        collection.save!
      end

      subject { get :manifest, { id: 'col1' } }

      it { is_expected.to have_http_status(:success) }

      it "returns IIIF manifest json" do
        expect(subject.body).to eq('{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"http://test.host/iiif-api/collection/col1/manifest","@type":"sc:Manifest","label":"something","description":"blahbalh","license":"http://creativecommons.org/publicdomain/mark/1.0/","within":"http://test.host/collections/col_parent","metadata":[{"label":"Abstract","value":["abs"]},{"label":"Subject: MESH","value":["bcd","efg"]}],"sequences":[{"@id":"http://test.host/iiif-api/collection/col1/sequence/basic","@type":"sc:Sequence","label":"basic","canvases":[{"@id":"http://test.host/iiif-api/generic_file/testa1/canvas/p1","@type":"sc:Canvas","label":"p1","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa1/annotation/p1","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa1/canvas/p1","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa1/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa1","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]},{"@id":"http://test.host/iiif-api/generic_file/testa2/canvas/p2","@type":"sc:Canvas","label":"p2","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa2/annotation/p2","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa2/canvas/p2","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa2/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa2","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]},{"@id":"http://test.host/iiif-api/generic_file/testa3/canvas/p3","@type":"sc:Canvas","label":"p3","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa3/annotation/p3","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa3/canvas/p3","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa3/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa3","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]}]}]}')
      end
    end

    describe '#generate_manifest' do
      before do
        allow(collection).to receive(:members).and_return([
          GenericFile.new(id: 'gf3', page_number: '11'),
          GenericFile.new(id: 'gf1', page_number: '9'),
          GenericFile.new(id: 'gf2', page_number: '10')
        ])
        allow(collection).to receive(:parent).and_return(
          Collection.new(id: 'col_parent')
        )
      end

      subject { controller.send(:generate_manifest, collection) }

      it { is_expected.to be_an_instance_of(IIIF::Presentation::Manifest) }

      it 'generates correct type' do
        expect(subject['@type']).to eq('sc:Manifest')
      end

      it 'generates correct id' do
        expect(subject['@id']).to eq(
          'http://test.host/iiif-api/collection/col1/manifest')
      end

      it 'generates correct label' do
        expect(subject['label']).to eq('something')
      end

      it 'generates correct within' do
        expect(subject['within']).to eq('http://test.host/collections/col_parent')
      end

      it 'generates correct metadata' do
        expect(subject['metadata'].count).to eq(2)
        expect(subject['metadata'].find {|o|
          o['label'] == 'Abstract' }['value']).to eq(['abs'])
        expect(subject['metadata'].find {|o|
          o['label'] == 'Subject: MESH' }['value']).to eq(['bcd', 'efg'])
      end

      it 'generates correct description' do
        expect(subject['description']).to eq('blahbalh')
      end

      it 'generates correct license' do
        expect(subject['license']).to eq(
          'http://creativecommons.org/publicdomain/mark/1.0/')
      end

      it 'generates correct sequence' do
        expect(subject.sequences.first).to be_an_instance_of(
          IIIF::Presentation::Sequence)
        expect(subject.sequences.first['@id']).to eq(
          'http://test.host/iiif-api/collection/col1/sequence/basic')
        expect(subject.sequences.first['canvases'].count).to eq(3)
      end
    end
  end

  describe "GET sequence" do
    let(:collection) { Collection.new(id: 'col1', title: 'something') }

    describe '#canvas' do
      before do
        collection.apply_depositor_metadata(user.user_key)
        (1..3).each do |nr|
          generic_file = GenericFile.new(id: "testa#{nr}", page_number: nr)
          generic_file.apply_depositor_metadata(user.user_key)
          generic_file.save!
          collection.members << generic_file
        end
        collection.save!
      end

      subject { get :sequence, { id: 'col1', name: 'blah' } }

      it { is_expected.to have_http_status(:success) }

      it "returns IIIF sequence json" do
        expect(subject.body).to eq('{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"http://test.host/iiif-api/collection/col1/sequence/blah","@type":"sc:Sequence","label":"blah","canvases":[{"@id":"http://test.host/iiif-api/generic_file/testa1/canvas/p1","@type":"sc:Canvas","label":"p1","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa1/annotation/p1","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa1/canvas/p1","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa1/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa1","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]},{"@id":"http://test.host/iiif-api/generic_file/testa2/canvas/p2","@type":"sc:Canvas","label":"p2","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa2/annotation/p2","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa2/canvas/p2","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa2/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa2","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]},{"@id":"http://test.host/iiif-api/generic_file/testa3/canvas/p3","@type":"sc:Canvas","label":"p3","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa3/annotation/p3","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa3/canvas/p3","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa3/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa3","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]}]}')
      end
    end

    describe '#generate_sequence' do
      before do
        allow(collection).to receive(:members).and_return([
          GenericFile.new(id: 'gf3', page_number: '11'),
          GenericFile.new(id: 'gf1', page_number: '9'),
          GenericFile.new(id: 'gf2', page_number: '10')
        ])
      end

      subject { controller.send(:generate_sequence, collection, 'awesome') }

      it { is_expected.to be_an_instance_of(IIIF::Presentation::Sequence) }

      it 'generates correct type' do
        expect(subject['@type']).to eq('sc:Sequence')
      end

      context 'passed name' do
        it 'generates correct sequence @id' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/collection/col1/sequence/awesome')
        end

        it 'generates correct label' do
          expect(subject['label']).to eq('awesome')
        end
      end

      context 'default name' do
        subject { controller.send(:generate_sequence, collection) }

        it 'generates correct sequence @id' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/collection/col1/sequence/basic')
        end

        it 'generates correct label' do
          expect(subject['label']).to eq('basic')
        end
      end

      context 'canvases' do
        subject {
          controller.send(:generate_sequence, collection, 'awesome').canvases
        }

        it 'makes 3 canvases' do
          expect(subject.count).to eq(3)
        end

        it 'makes the proper canvas objects' do
          subject.each do |canvas|
            expect(canvas).to be_an_instance_of(IIIF::Presentation::Canvas)
          end
        end

        it 'puts the canvases in proper order' do
          expect(subject.map {|o| o['@id'] }).to eq([
            "http://test.host/iiif-api/generic_file/gf1/canvas/p9",
            "http://test.host/iiif-api/generic_file/gf2/canvas/p10",
            "http://test.host/iiif-api/generic_file/gf3/canvas/p11"
          ])
        end
      end
    end
  end

  describe "GET canvas" do
    describe '#canvas' do
      before do
        @generic_file = GenericFile.new(id: 'testa')
        @generic_file.apply_depositor_metadata(user.user_key)
        @generic_file.save!
      end

      subject { get :canvas, { id: 'testa', name: 'blah' } }

      it { is_expected.to have_http_status(:success) }

      it "returns IIIF canvas json" do
        expect(subject.body).to eq('{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"http://test.host/iiif-api/generic_file/testa/canvas/blah","@type":"sc:Canvas","label":"blah","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa/annotation/blah","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa/canvas/blah","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]}')
      end
    end

    describe '#generate_canvas' do
      let(:generic_file) { GenericFile.new(id: 'testa') }
      subject { controller.send(:generate_canvas, generic_file, 'p33') }

      it { is_expected.to be_an_instance_of(IIIF::Presentation::Canvas) }

      it 'generates correct type' do
        expect(subject['@type']).to eq('sc:Canvas')
      end

      it 'generates correct images' do
        expect(subject['images'].first).to be_an_instance_of(
          IIIF::Presentation::Annotation)
        expect(subject['images'].first['@id']).to eq(
          'http://test.host/iiif-api/generic_file/testa/annotation/p33')
      end

      context 'passed name' do
        it 'generates correct canvas path' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/generic_file/testa/canvas/p33')
        end

        it 'generates correct label' do
          expect(subject['label']).to eq('p33')
        end
      end

      context 'derived name' do
        before do
          generic_file.page_number = 33
        end

        subject { controller.send(:generate_canvas, generic_file) }

        it 'generates correct canvas path' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/generic_file/testa/canvas/p33')
        end

        it 'generates correct label' do
          expect(subject['label']).to eq('p33')
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
      before do
        @generic_file = GenericFile.new(id: 'testa')
        @generic_file.apply_depositor_metadata(user.user_key)
        @generic_file.save!
      end

      subject { get :annotation, { id: 'testa', name: 'blah' } }

      it { is_expected.to have_http_status(:success) }

      it "returns IIIF annotation json" do
        expect(subject.body).to eq('{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"http://test.host/iiif-api/generic_file/testa/annotation/blah","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa/canvas/blah","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa/full/full/0/native.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}')
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
        expect(subject['resource']).to be_an_instance_of(
          IIIF::Presentation::ImageResource)
      end

      context 'passed name' do
        it 'generates correct annotation path' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/generic_file/testa/annotation/p33')
        end

        it 'generates correct on canvas path' do
          expect(subject['on']).to eq(
            'http://test.host/iiif-api/generic_file/testa/canvas/p33')
        end
      end

      context 'derived name' do
        before do
          @generic_file.page_number = 33
        end

        subject { controller.send(:generate_annotation, @generic_file) }
        it 'generates correct annotation path' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/generic_file/testa/annotation/p33')
        end

        it 'generates correct on canvas path' do
          expect(subject['on']).to eq(
            'http://test.host/iiif-api/generic_file/testa/canvas/p33')
        end
      end
    end
  end

  describe '#image_resource' do
    let(:generic_file) { GenericFile.new(id: 'testa') }
    subject { controller.send(:image_resource, generic_file) }

    it { is_expected.to be_an_instance_of(IIIF::Presentation::ImageResource) }

    it 'generates correct image path' do
      expect(subject['@id']).to eq(
        'http://test.host/image-service/testa/full/full/0/native.jpg')
    end

    it 'generates correct type' do
      expect(subject['@type']).to eq('dcterms:Image')
    end

    it 'generates correct format' do
      expect(subject['format']).to eq('image/jpeg')
    end

    it 'generates correct height' do
      expect(generic_file).to receive(:height).and_return(['20'])
      expect(subject['height']).to eq(20)
    end

    it 'generates correct width' do
      expect(generic_file).to receive(:width).and_return(['50'])
      expect(subject['width']).to eq(50)
    end

    context 'iif image service' do
      subject { controller.send(:image_resource, generic_file)['service'] }

      it 'generates correct @id' do
        expect(subject['@id']).to eq('http://test.host/image-service/testa')
      end

      it 'generates correct @context' do
        expect(subject['@context']).to eq(
          'http://iiif.io/api/image/2/context.json')
      end

      it 'generates correct profile' do
        expect(subject['profile']).to eq(
          'http://iiif.io/api/image/2/profiles/level2.json')
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
