require 'rails_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  before do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  describe "#show" do
    before do
      @collection = Collection.new(
        title: 'something',
        abstract: ['testa'], bibliographic_citation: ['cit'],
        digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
        subject_geographic: ['geo'], subject_name: ['subjn'],
        page_number: 11, multi_page: true
      )
      @collection.apply_depositor_metadata(@user.user_key)
      @collection.save!
    end

    it "should assign proper collection" do
      get :show, id: @collection
      expect(response).to be_successful
      expect(assigns(:collection).abstract).to eq(['testa'])
      expect(assigns(:collection).bibliographic_citation).to eq(['cit'])
      expect(assigns(:collection).digital_origin).to eq(['digo'])
      expect(assigns(:collection).mesh).to eq(['mesh'])
      expect(assigns(:collection).lcsh).to eq(['lcsh'])
      expect(assigns(:collection).subject_geographic).to eq(['geo'])
      expect(assigns(:collection).subject_name).to eq(['subjn'])
      expect(assigns(:collection).page_number).to eq(11)
      expect(assigns(:collection).multi_page).to eq(true)
    end
  end

  describe "#create" do
    it 'creates collection' do
      expect {
        post :create, id: @collection, collection: {
          title: 'something', description: 'desc',
          abstract: ['testa'], bibliographic_citation: ['cit'],
          digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
          subject_geographic: ['geo'], subject_name: ['subjn'],
          page_number: 11
        }
      }.to change { Collection.count }.by(1)
    end

    it 'populates the custom attributes' do
      post :create, id: @collection, collection: {
        title: 'something', description: 'desc',
        abstract: ['testa'], bibliographic_citation: ['cit'],
        digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
        subject_geographic: ['geo'], subject_name: ['subjn'],
        page_number: 11, multi_page: 'true'
      }
      expect(assigns(:collection).abstract).to eq(['testa'])
      expect(assigns(:collection).bibliographic_citation).to eq(['cit'])
      expect(assigns(:collection).digital_origin).to eq(['digo'])
      expect(assigns(:collection).mesh).to eq(['mesh'])
      expect(assigns(:collection).lcsh).to eq(['lcsh'])
      expect(assigns(:collection).subject_geographic).to eq(['geo'])
      expect(assigns(:collection).subject_name).to eq(['subjn'])
      expect(assigns(:collection).page_number).to eq('11')
      expect(assigns(:collection).multi_page).to eq(true)
    end
  end

  describe "#update" do
    before do
      @collection = Collection.new(
        title: 'something',
        abstract: ['testa'], bibliographic_citation: ['cit'],
        digital_origin: ['digo'], mesh: ['mesh'], lcsh: ['lcsh'],
        subject_geographic: ['geo'], subject_name: ['subjn'],
        page_number: 11, multi_page: true
      )
      @collection.apply_depositor_metadata(@user.user_key)
      @collection.save!
    end

    it "should update abstract" do
      patch :update, id: @collection, collection: { abstract: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).abstract).to eq(['dudu'])
    end

    it "should update bibliographic_citation" do
      patch :update, id: @collection, collection: {
        bibliographic_citation: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).bibliographic_citation).to eq(['dudu'])
    end

    it "should update subject_name" do
      patch :update, id: @collection, collection: { subject_name: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).subject_name).to eq(['dudu'])
    end

    it "should update subject_geographic" do
      patch :update, id: @collection, collection: { subject_geographic: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).subject_geographic).to eq(['dudu'])
    end

    it "should update mesh" do
      patch :update, id: @collection, collection: { mesh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).mesh).to eq(['dudu'])
    end

    it "should update lcsh" do
      patch :update, id: @collection, collection: { lcsh: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).lcsh).to eq(['dudu'])
    end

    it "should update digital_origin" do
      patch :update, id: @collection, collection: { digital_origin: ['dudu'] }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).digital_origin).to eq(['dudu'])
    end

    it "should update page_number" do
      patch :update, id: @collection, collection: { page_number: 22 }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).page_number).to eq('22')
    end

    it "should update multi_page" do
      patch :update, id: @collection, collection: { multi_page: false }
      expect(response).to redirect_to(
        @routes.url_helpers.collection_path(@collection))
      expect(assigns(:collection).multi_page).to eq(false)
    end
  end
end
