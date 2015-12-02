require 'rails_helper'

describe BatchController do
  let(:user) { create(:user, display_name: 'Display Name',
                      :formal_name => 'Name, Formal') }
  before do
    @routes = Sufia::Engine.routes
  end

  describe '#edit' do
    let(:batch) { Batch.create }

    before do
      allow_any_instance_of(Nuldap).to receive(
        :search).and_return([true, {
          'mail' => ['a@b.c'],
          'sn' => ['Name'],
          'givenName' => ['Formal']
        }])
      sign_in user
    end

    it 'sets creator to formal_name of the depositor' do
      get :edit, id: batch.id
      expect(assigns(:form).creator).to eq(['Name, Formal'])
      expect(assigns(:form).model.creator).to eq(['Name, Formal'])
    end
  end
end
