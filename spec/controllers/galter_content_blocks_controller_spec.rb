require 'rails_helper'

describe GalterContentBlocksController do
  let(:user) { create(:user) }
  let(:admin) { Role.create(name: 'admin') }
  let!(:researcher) {
    ContentBlock.create(name: 'featured_researcher', value: 'content')
  }

  describe '#destroy' do
    subject { delete :destroy, id: researcher.id }

    describe 'by anonymous user' do
      it { is_expected.to redirect_to('/users/sign_in') }

      it "doesn't delete the researcher" do
        expect { subject }.not_to change { ContentBlock.count }
      end
    end

    describe 'authenticated non-admin user' do
      before { sign_in user }

      it { is_expected.to redirect_to('/') }

      it "doesn't delete the researcher" do
        expect { subject }.not_to change { ContentBlock.count }
      end

      it 'notifies of failure' do
        subject
        expect(flash['alert']).to eq(
          'You are not authorized to access this page.')
      end
    end

    describe 'authenticated admin user' do
      before do
        user.add_role(admin.name)
        sign_in user
      end

      it { is_expected.to redirect_to('/') }

      it "doesn't delete the researcher" do
        expect { subject }.to change { ContentBlock.count }.by(-1)
      end
    end
  end

  describe '#refeature_researcher' do
    let(:one_week_ago) { Time.zone.now - 1.week }
    let!(:researcher1) {
      researcher.created_at = one_week_ago
      researcher.save
      researcher
    }
    subject { patch :refeature_researcher, id: researcher1.id }

    describe 'by anonymous user' do
      it { is_expected.to redirect_to('/users/sign_in') }

      it "doesn't change the created_at date" do
        expect { subject }.not_to change {
          researcher.reload.created_at
        }
      end
    end

    describe 'authenticated non-admin user' do
      before { sign_in user }

      it { is_expected.to redirect_to('/') }

      it "doesn't change the created_at date" do
        expect { subject }.not_to change {
          researcher.reload.created_at
        }
      end

      it 'notifies of failure' do
        subject
        expect(flash['alert']).to eq(
          'You are not authorized to access this page.')
      end
    end

    describe 'authenticated admin user' do
      before do
        user.add_role(admin.name)
        sign_in user
      end

      it { is_expected.to redirect_to('/') }

      it "changes the created_at date" do
        expect { subject }.to change { researcher1.reload.created_at }
      end
    end
  end
end
