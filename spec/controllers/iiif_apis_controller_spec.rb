require 'rails_helper'
require 'iiif/presentation'

RSpec.describe IiifApisController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }

  describe 'authorization' do
    let(:col) { make_collection(user, visibility: 'restricted', id: 'col1') }
    let(:gf) { make_generic_file(user, visibility: 'restricted', id: 'gf1') }

    context 'unauthorized user' do
      it 'is unable to to view manifest' do
        expect(
          get :manifest, { id: col.id }
        ).to redirect_to('/users/sign_in')
      end

      it 'is unable to to view sequence' do
        expect(
          get :sequence, { id: col.id, name: 'blah' }
        ).to redirect_to('/users/sign_in')
      end

      it 'is unable to to view canvas' do
        expect(
          get :canvas, { id: gf.id, name: 'blah' }
        ).to redirect_to('/users/sign_in')
      end

      it 'is unable to to view annotation' do
        expect(
          get :annotation, { id: gf.id, name: 'blah' }
        ).to redirect_to('/users/sign_in')
      end
    end

    context 'authorized user' do
      before do
        sign_in user
      end

      it 'is able to to view manifest' do
        get :manifest, { id: col.id }
        expect(response).to have_http_status(:success)
      end

      it 'is able to to view sequence' do
        get :sequence, { id: col.id, name: 'blah' }
        expect(response).to have_http_status(:success)
      end

      it 'is able to to view canvas' do
        get :canvas, { id: gf.id, name: 'blah' }
        expect(response).to have_http_status(:success)
      end

      it 'is able to to view annotation' do
        get :annotation, { id: gf.id, name: 'blah' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'of sequence of collection members' do
      let(:col) { make_collection(
        user, visibility: 'open', member_ids: [gf.id, gf_stranger.id, gf_public.id]
      ) }
      let(:gf) { make_generic_file(
        user, visibility: 'restricted', id: 'gf1', page_number: 1
      ) }
      let(:gf_stranger) { make_generic_file(
        FactoryGirl.create(:user), visibility: 'restricted', id: 'gf2',
        page_number: 2
      ) }
      let(:gf_public) { make_generic_file(
        FactoryGirl.create(:user), visibility: 'open', id: 'gf3',
        page_number: 3
      ) }

      subject { get :sequence, { id: col.id, name: 'blah' } }

      before do
        allow_any_instance_of(GenericFile).to receive(:height) { ['300'] }
        allow_any_instance_of(GenericFile).to receive(:width) { ['600'] }
      end

      describe 'requested by anonymous user' do
        it 'only shows the publicly visible member' do
          expect(subject.body).to include(gf_public.id)
          expect(subject.body).not_to include(gf.id)
          expect(subject.body).not_to include(gf_stranger.id)
        end
      end

      describe 'requested by file owner user' do
        it 'only shows the publicly visible and owned members' do
          sign_in(user)
          expect(subject.body).to include(gf_public.id)
          expect(subject.body).to include(gf.id)
          expect(subject.body).not_to include(gf_stranger.id)
        end
      end

      describe 'requested by admin' do
        it 'shows all members' do
          sign_in(FactoryGirl.create(:admin_user))
          expect(subject.body).to include(gf_public.id)
          expect(subject.body).to include(gf.id)
          expect(subject.body).to include(gf_stranger.id)
        end
      end
    end
  end

  describe "GET manifest" do
    let(:collection) { Collection.new(
      id: 'col1', title: 'something', description: 'blahbalh',
      rights: ['http://creativecommons.org/publicdomain/mark/1.0/'],
      abstract: ['abs'], mesh: ['bcd', 'efg'], tag: ['tag']
    ) }

    let(:col_parent) { make_collection(user, { id: 'col_parent' }) }

    describe '#manifest' do
      before do
        allow_any_instance_of(GenericFile).to receive(:height) { ['0'] }
        allow_any_instance_of(GenericFile).to receive(:width) { ['0'] }
        collection.apply_depositor_metadata(user.user_key)
        collection.save!
        (1..3).each do |nr|
          generic_file = make_generic_file(
            user, id: "testa#{nr}", page_number: nr)
          collection.members << generic_file
        end
        collection.parent = col_parent
        collection.save!
        sign_in(user)
      end

      subject { get :manifest, { id: 'col1' } }

      it "returns IIIF manifest json" do
        expect(subject).to have_http_status(:success)
        expect(subject.body).to include('{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"http://test.host/iiif-api/collection/col1/manifest","@type":"sc:Manifest","label":"something","description":"blahbalh","license":"http://creativecommons.org/publicdomain/mark/1.0/","logo":"http://test.host/assets/iiif_nm_logo')
        expect(subject.body).to include(',"within":"http://test.host/collections/col_parent","metadata":[{"label":"Keyword","value":["tag"]},{"label":"Abstract","value":["abs"]},{"label":"Publisher","value":["DigitalHub. Galter Health Sciences Library \u0026 Learning Center"]},{"label":"Subject: MESH","value":["bcd","efg"]}],"sequences":[{"@id":"http://test.host/iiif-api/collection/col1/sequence/basic","@type":"sc:Sequence","label":"basic","canvases":[{"@id":"http://test.host/iiif-api/generic_file/testa1/canvas/p1","@type":"sc:Canvas","label":"p1","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa1/annotation/p1","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa1/canvas/p1","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa1/full/full/0/default.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa1","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]},{"@id":"http://test.host/iiif-api/generic_file/testa2/canvas/p2","@type":"sc:Canvas","label":"p2","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa2/annotation/p2","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa2/canvas/p2","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa2/full/full/0/default.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa2","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]},{"@id":"http://test.host/iiif-api/generic_file/testa3/canvas/p3","@type":"sc:Canvas","label":"p3","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa3/annotation/p3","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa3/canvas/p3","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa3/full/full/0/default.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa3","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]}]}]}')
      end
    end

    describe '#generate_manifest' do
      let(:gf3) { make_generic_file(user, id: 'gf3', page_number: 11) }
      let(:gf1) { make_generic_file(user, id: 'gf1', page_number: 9) }
      let(:gf2) { make_generic_file(user, id: 'gf2', page_number: 10) }

      before do
        allow_any_instance_of(GenericFile).to receive(:height) { ['0'] }
        allow_any_instance_of(GenericFile).to receive(:width) { ['0'] }
        allow(collection).to receive(:parent).and_return(
          Collection.new(id: 'col_parent')
        )
        collection.apply_depositor_metadata(user.user_key)
        collection.member_ids = [gf3.id, gf1.id, gf2.id]
        collection.save
        sign_in(user)
      end

      subject { controller.send(:generate_manifest, collection) }

      specify do
        expect(subject).to be_an_instance_of(IIIF::Presentation::Manifest)
        expect(subject['@type']).to eq('sc:Manifest')
        expect(subject['@id']).to eq(
          'http://test.host/iiif-api/collection/col1/manifest')
        expect(subject['label']).to eq('something')
        expect(subject['within']).to eq('http://test.host/collections/col_parent')
      end

      it 'generates correct metadata' do
        expect(subject['metadata'].count).to eq(4)
        expect(subject['metadata'].find {|o|
          o['label'] == 'Abstract' }['value']).to eq(['abs'])
        expect(subject['metadata'].find {|o|
          o['label'] == 'Subject: MESH' }['value']).to eq(['bcd', 'efg'])
        expect(subject['metadata'].find {|o|
          o['label'] == 'Keyword' }['value']).to eq(['tag'])
        expect(subject['metadata'].find {|o|
          o['label'] == 'Publisher' }['value']).to eq(['DigitalHub. Galter Health Sciences Library & Learning Center'])
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
    let(:collection) {
      Collection.new(id: 'col1', title: 'something', tag: ['tag'])
    }

    describe '#canvas' do
      before do
        allow_any_instance_of(GenericFile).to receive(:height) { ['0'] }
        allow_any_instance_of(GenericFile).to receive(:width) { ['0'] }
        collection.apply_depositor_metadata(user.user_key)
        collection.save!
        (1..3).each do |nr|
          generic_file = make_generic_file(
            user, id: "testa#{nr}", page_number: nr)
          collection.members << generic_file
        end
        collection.save
        collection.update_index
        sign_in(FactoryGirl.create(:admin_user))
      end

      subject { get :sequence, { id: 'col1', name: 'blah' } }

      it "returns IIIF sequence json" do
        expect(subject).to have_http_status(:success)
        expect(subject.body).to eq('{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"http://test.host/iiif-api/collection/col1/sequence/blah","@type":"sc:Sequence","label":"blah","canvases":[{"@id":"http://test.host/iiif-api/generic_file/testa1/canvas/p1","@type":"sc:Canvas","label":"p1","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa1/annotation/p1","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa1/canvas/p1","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa1/full/full/0/default.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa1","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]},{"@id":"http://test.host/iiif-api/generic_file/testa2/canvas/p2","@type":"sc:Canvas","label":"p2","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa2/annotation/p2","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa2/canvas/p2","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa2/full/full/0/default.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa2","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]},{"@id":"http://test.host/iiif-api/generic_file/testa3/canvas/p3","@type":"sc:Canvas","label":"p3","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa3/annotation/p3","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa3/canvas/p3","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa3/full/full/0/default.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa3","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]}]}')
      end
    end

    describe '#generate_sequence' do
      let(:gf1) { make_generic_file(user, id: 'gf1', page_number: 9) }
      let(:gf2) { make_generic_file(user, id: 'gf2', page_number: 10) }
      let(:gf3) { make_generic_file(user, id: 'gf3', page_number: 11) }
      let(:collection) { make_collection(
        user, id: 'col1', member_ids: [gf1.id, gf2.id, gf3.id]
      ) }

      before do
        allow_any_instance_of(GenericFile).to receive(:height) { ['0'] }
        allow_any_instance_of(GenericFile).to receive(:width) { ['0'] }
        sign_in(user)
      end

      subject { controller.send(
        :generate_sequence, collection, 'awesome'
      ) }

      it 'generates correct type' do
        expect(subject).to be_an_instance_of(IIIF::Presentation::Sequence)
        expect(subject['@type']).to eq('sc:Sequence')
      end

      context 'passed name' do
        it 'generates correct sequence @id and label' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/collection/col1/sequence/awesome')
          expect(subject['label']).to eq('awesome')
        end
      end

      context 'default name' do
        subject { controller.send(:generate_sequence, collection) }

        it 'generates correct sequence @id and label' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/collection/col1/sequence/basic')
          expect(subject['label']).to eq('basic')
        end
      end

      context 'canvases' do
        subject {
          controller.send(:generate_sequence, collection, 'awesome').canvases
        }

        it 'makes 3 canvases and proper order' do
          expect(subject.count).to eq(3)
          subject.each do |canvas|
            expect(canvas).to be_an_instance_of(IIIF::Presentation::Canvas)
          end
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
        allow_any_instance_of(GenericFile).to receive(:height) { ['0'] }
        allow_any_instance_of(GenericFile).to receive(:width) { ['0'] }
        @generic_file = make_generic_file(user, id: 'testa')
        sign_in user
      end

      subject { get :canvas, { id: 'testa', name: 'blah' } }

      it "returns IIIF canvas json" do
        expect(subject).to have_http_status(:success)
        expect(subject.body).to eq('{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"http://test.host/iiif-api/generic_file/testa/canvas/blah","@type":"sc:Canvas","label":"blah","height":0,"width":0,"images":[{"@id":"http://test.host/iiif-api/generic_file/testa/annotation/blah","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa/canvas/blah","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa/full/full/0/default.jpg","@type":"dcterms:Image","format":"image/jpeg","height":0,"width":0,"service":{"@id":"http://test.host/image-service/testa","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}]}')
      end
    end

    describe '#generate_canvas' do
      let(:generic_file) { GenericFile.new(id: 'testa') }
      subject { controller.send(
        :generate_canvas, generic_file.to_solr.with_indifferent_access, 'p33'
      ) }

      before do
        allow(generic_file).to receive(:height) { ['300'] }
        allow(generic_file).to receive(:width) { ['600'] }
      end

      specify do
        expect(subject).to be_an_instance_of(IIIF::Presentation::Canvas)
        expect(subject['@type']).to eq('sc:Canvas')
        expect(subject['images'].first).to be_an_instance_of(
          IIIF::Presentation::Annotation)
        expect(subject['images'].first['@id']).to eq(
          'http://test.host/iiif-api/generic_file/testa/annotation/p33')
      end

      context 'passed name' do
        it 'generates correct canvas path and label' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/generic_file/testa/canvas/p33')
          expect(subject['label']).to eq('p33')
        end
      end

      context 'derived name' do
        before do
          generic_file.page_number_actual = 33
        end

        subject { controller.send(
          :generate_canvas, generic_file.to_solr.with_indifferent_access
        ) }

        it 'generates correct canvas path and label' do
          expect(subject['@id']).to eq(
            'http://test.host/iiif-api/generic_file/testa/canvas/p33')
          expect(subject['label']).to eq('p33')
        end
      end

      it 'generates correct height and width' do
        expect(subject['height']).to eq(300)
        expect(subject['width']).to eq(600)
      end
    end
  end

  describe "GET annotation" do
    describe '#annotation' do
      before do
        allow_any_instance_of(GenericFile).to receive(:height) { ['300'] }
        allow_any_instance_of(GenericFile).to receive(:width) { ['600'] }
        @generic_file = make_generic_file(user, id: 'testa')
        sign_in user
      end

      subject { get :annotation, { id: 'testa', name: 'blah' } }

      it "returns IIIF annotation json" do
        expect(subject).to have_http_status(:success)
        expect(subject.body).to eq('{"@context":"http://iiif.io/api/presentation/2/context.json","@id":"http://test.host/iiif-api/generic_file/testa/annotation/blah","@type":"oa:Annotation","on":"http://test.host/iiif-api/generic_file/testa/canvas/blah","motivation":"sc:painting","resource":{"@id":"http://test.host/image-service/testa/full/full/0/default.jpg","@type":"dcterms:Image","format":"image/jpeg","height":300,"width":600,"service":{"@id":"http://test.host/image-service/testa","@context":"http://iiif.io/api/image/2/context.json","profile":"http://iiif.io/api/image/2/profiles/level2.json"}}}')
      end
    end

    describe '#generate_annotation' do
      before do
        @generic_file = GenericFile.new(id: 'testa')
        allow(@generic_file).to receive(:height) { ['300'] }
        allow(@generic_file).to receive(:width) { ['600'] }
      end

      subject { controller.send(
        :generate_annotation, @generic_file.to_solr.with_indifferent_access, 'p33'
      ) }

      specify do
        expect(subject).to be_an_instance_of(IIIF::Presentation::Annotation)
        expect(subject['@type']).to eq('oa:Annotation')
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
          @generic_file.page_number_actual = 33
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
    subject { controller.send(
      :image_resource, generic_file.to_solr.with_indifferent_access
    ) }

    before do
      allow(generic_file).to receive(:height) { ['300'] }
      allow(generic_file).to receive(:width) { ['600'] }
    end

    specify do
      expect(subject).to be_an_instance_of(IIIF::Presentation::ImageResource)
      expect(subject['@id']).to eq(
        'http://test.host/image-service/testa/full/full/0/default.jpg')
      expect(subject['@type']).to eq('dcterms:Image')
      expect(subject['format']).to eq('image/jpeg')
      expect(subject['height']).to eq(300)
      expect(subject['width']).to eq(600)
    end

    context 'iif image service' do
      subject { controller.send(
        :image_resource, generic_file.to_solr.with_indifferent_access)['service']
      }

      it 'generates correct @id, @context and profile' do
        expect(subject['@id']).to eq('http://test.host/image-service/testa')
        expect(subject['@context']).to eq(
          'http://iiif.io/api/image/2/context.json')
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
