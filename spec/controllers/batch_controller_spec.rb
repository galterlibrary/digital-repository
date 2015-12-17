require 'rails_helper'

describe BatchController do
  let(:user) { create(:user, display_name: 'Display Name',
                      :formal_name => 'Name, Formal') }
  before do
    @routes = Sufia::Engine.routes
  end

  describe '#update' do
    let(:gf1) { make_generic_file(user, title: ['abc'], id: 'gf1') }
    let(:gf2) { make_generic_file(user, title: ['bcd'], id: 'gf2') }
    let(:batch) { Batch.create(generic_file_ids: ['gf1', 'gf2']) }

    describe 'doi minting job scheduling' do
      before do
        sign_in user
        batch_job = double('batch')
        allow(BatchUpdateJob).to receive(:new).and_return(batch_job)
        allow(Sufia.queue).to receive(:push).with(batch_job)
      end

      it 'schedules the job for both generic files' do
        job1 =  double('one')
        job2 =  double('two')
        expect(MintDoiJob).to receive(:new).with(gf1.id).and_return(job1)
        expect(MintDoiJob).to receive(:new).with(gf2.id).and_return(job2)
        expect(Sufia.queue).to receive(:push).with(job1)
        expect(Sufia.queue).to receive(:push).with(job2)
        patch :update, id: batch, visibility: 'open',
              :title => { 'gf1' => ['aaa'], 'gf2' => ['bbb'] },
              :generic_file => {}
      end
    end
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
