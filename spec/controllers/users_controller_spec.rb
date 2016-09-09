require 'rails_helper'

describe UsersController do
  routes { Sufia::Engine.routes }

  describe "#index" do
    it 'can sort by username' do
      u1 = create(:user, username: 'good', display_name: 'Good Mo')
      u2 = create(:user, username: 'bad', display_name: 'Bad Mo')
      get :index, sort: 'login', uq: ''
      expect(assigns(:users).count).to eq(2)
      expect(assigns(:users).first).to eq(u2)
      expect(assigns(:users).second).to eq(u1)
    end

    describe 'json' do
      it 'returns a hash of users' do
        create(:user, username: 'bad', display_name: 'Bad Mo')
        create(:user, username: 'good', display_name: 'Good Mo')
        get :index, format: 'json'
        expect(assigns(:users).count).to eq(2)
        resp_hash = JSON.parse(response.body)
        expect(resp_hash.count).to eq(2)
        expect(resp_hash.map {|o| o['id'] }).to include('bad')
        expect(resp_hash.map {|o| o['id'] }).to include('good')
        expect(resp_hash.map {|o| o['text'] }).to include('Bad Mo (bad)')
        expect(resp_hash.map {|o| o['text'] }).to include('Good Mo (good)')
      end

      it 'can filter users' do
        create(:user, username: 'bad', display_name: 'Bad Mo')
        create(:user, username: 'good', display_name: 'Good Mo')
        get :index, format: 'json', uq: 'goo'
        expect(assigns(:users).count).to eq(1)
        resp_hash = JSON.parse(response.body)
        expect(resp_hash.count).to eq(1)
        expect(resp_hash.first['id']).to eq('good')
        expect(resp_hash.first['text']).to eq('Good Mo (good)')
      end

      it 'can ignore case' do
        create(:user, username: 'bad', display_name: 'Bad Mof')
        create(:user, username: 'good', display_name: 'Good mof')
        create(:user, username: 'nah', display_name: 'Good Dof')
        get :index, format: 'json', uq: 'MOF'
        expect(assigns(:users).count).to eq(2)
      end

      it 'returns the first ten users' do
        create_list(:user, 12)
        get :index, format: 'json'
        expect(assigns(:users).count).to eq(10)
        resp_hash = JSON.parse(response.body)
        expect(resp_hash.count).to eq(10)
      end
    end
  end
end
