require 'rails_helper'

describe BatchEditsController do
  before do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  describe "#destroy_collection" do
    before do
      @file = make_generic_file(@user, id: 'nukeme')
      @col = make_collection(@user, id: 'killme')
    end
    subject {
      delete :destroy_collection, {
        'batch_document_ids' => ['nukeme', 'killme'],
        'update_type'=> 'delete_all',
        'return_controller' => 'my/files'
      }
    }

    it 'does not allow non-admin owner to delete files' do
      expect { subject }.not_to change(ActiveFedora::Base, :count)
      expect(flash[:alert]).to match('You are not authorized')
      expect(response).to redirect_to('/dashboard/files')
    end

    it 'allows an admin user to delete files' do
      @user = FactoryGirl.create(:user)
      @user.add_role(Role.create(name: 'admin').name)
      sign_in @user

      expect { subject }.to change(ActiveFedora::Base, :count).by(-2)
      expect { GenericFile.find('nukeme') }.to raise_error(Ldp::Gone)
      expect { Collection.find('killme') }.to raise_error(Ldp::Gone)
      expect(flash[:notice]).to match('Batch delete complete')
    end
  end
end
