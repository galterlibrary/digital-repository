require 'rails_helper'

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
    it "returns http success" do
      get :canvas, { id: '1234', name: 'blah' }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET annotation" do
    it "returns http success" do
      get :annotation, { id: '1234', name: 'blah' }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET list" do
    it "returns http success" do
      get :list, { id: '1234', name: 'blah' }
      expect(response).to have_http_status(:success)
    end
  end
end
