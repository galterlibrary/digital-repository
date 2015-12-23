require 'rails_helper'

describe BatchEditsController do
  describe "#destroy_collection" do
    let(:user) { create(:user) }
    before do
      @file = make_generic_file(user, id: 'nukeme', doi: ['a', 'b'],
                                title: ['Nuke'])
      @file2 = make_generic_file(user, id: 'kaput', doi: ['c'],
                                 title: ['Kaput'])
      @col = make_collection(user, id: 'killme')
    end

    subject {
      delete :destroy_collection, {
        'batch_document_ids' => ['nukeme', 'kaput', 'killme'],
        'update_type'=> 'delete_all',
        'return_controller' => 'my/files'
      }
    }

    context 'non-admin user' do
      before { sign_in user }

      it 'does not allow non-admin owner to delete files' do
        expect { subject }.not_to change(ActiveFedora::Base, :count)
        expect(flash[:alert]).to match('You are not authorized')
        expect(response).to redirect_to('/dashboard/files')
      end
    end

    context 'admin user' do
      let(:user) { create(:admin_user, username: 'admin') }
      before { sign_in user }

      it 'allows an admin user to delete files' do
        expect { subject }.to change(ActiveFedora::Base, :count).by(-3)
        expect { GenericFile.find('nukeme') }.to raise_error(Ldp::Gone)
        expect { Collection.find('kaput') }.to raise_error(Ldp::Gone)
        expect { Collection.find('killme') }.to raise_error(Ldp::Gone)
        expect(flash[:notice]).to match('Batch delete complete')
      end

      it 'schedules doi deactivation jobs for the generic files only' do
        job1 = double('job1')
        job2 = double('job2')
        job3 = double('job3')
        expect(DeactivateDoiJob).to receive(:new).with(
          'nukeme', 'a', 'admin', 'Nuke').and_return(job1)
        expect(DeactivateDoiJob).to receive(:new).with(
          'nukeme', 'b', 'admin', 'Nuke').and_return(job2)
        expect(DeactivateDoiJob).to receive(:new).with(
          'kaput', 'c', 'admin', 'Kaput').and_return(job3)
        expect(Sufia.queue).to receive(:push).with(job1)
        expect(Sufia.queue).to receive(:push).with(job2)
        expect(Sufia.queue).to receive(:push).with(job3)
        subject
      end
    end
  end

  describe "#update" do
    let(:user) { create(:user) }
    before do
      @file = make_generic_file(user, id: 'nukeme', doi: ['a', 'b'],
                                title: ['Nuke'])
      @file2 = make_generic_file(user, id: 'kaput', doi: ['c'],
                                 title: ['Kaput'])
      @col = make_collection(user, id: 'killme')
    end

    subject {
      patch :update, {
        'batch_document_ids' => ['nukeme', 'kaput'],
        'update_type'=> 'delete_all',
        'return_controller' => 'my/files'
      }
    }

    context 'non-admin user' do
      before { sign_in user }

      it 'does not allow non-admin owner to delete files' do
        expect { subject }.not_to change(ActiveFedora::Base, :count)
        expect(flash[:alert]).to match('You are not authorized')
        expect(response).to redirect_to('/dashboard/files')
      end
    end

    context 'admin user' do
      let(:user) { create(:admin_user, username: 'admin') }
      before { sign_in user }

      it 'allows an admin user to delete files' do
        expect { subject }.to change(ActiveFedora::Base, :count).by(-2)
        expect { GenericFile.find('nukeme') }.to raise_error(Ldp::Gone)
        expect { Collection.find('kaput') }.to raise_error(Ldp::Gone)
      end

      it 'schedules doi deactivation jobs for the generic files only' do
        job1 = double('job1')
        job2 = double('job2')
        job3 = double('job3')
        expect(DeactivateDoiJob).to receive(:new).with(
          'nukeme', 'a', 'admin', 'Nuke').and_return(job1)
        expect(DeactivateDoiJob).to receive(:new).with(
          'nukeme', 'b', 'admin', 'Nuke').and_return(job2)
        expect(DeactivateDoiJob).to receive(:new).with(
          'kaput', 'c', 'admin', 'Kaput').and_return(job3)
        expect(Sufia.queue).to receive(:push).with(job1)
        expect(Sufia.queue).to receive(:push).with(job2)
        expect(Sufia.queue).to receive(:push).with(job3)
        subject
      end
    end
  end
end
