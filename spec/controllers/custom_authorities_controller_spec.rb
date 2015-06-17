require 'rails_helper'

RSpec.describe CustomAuthoritiesController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  describe '#verify_user' do
    context 'invalid query' do
      describe 'no params passed' do
        subject { get :verify_user }

        it { is_expected.to have_http_status(:success) }

        it 'indicates that user is not verified' do
          expect(JSON.parse(subject.body)['verified']).to be_falsy
          expect(JSON.parse(subject.body)['message']).to match(/too short/)
        end
      end

      describe 'short param passed' do
        subject { get :verify_user, q: 'Zb' }

        it { is_expected.to have_http_status(:success) }

        it 'indicates that user is not verified' do
          expect(JSON.parse(subject.body)['verified']).to be_falsy
          expect(JSON.parse(subject.body)['message']).to match(/too short/)
        end
      end
    end

    context 'valid query' do
      describe 'one user found in LDAP' do
        before do
          allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
            { 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'] }
          ])
        end

        subject { get :verify_user, q: 'Zbyszko Z Bogdanca' }

        it { is_expected.to have_http_status(:success) }

        it 'indicates that user is verified' do
          expect(JSON.parse(subject.body)['verified']).to be_truthy
        end

        it 'returns users first and last name' do
          expect(JSON.parse(subject.body)['first']).to eq('Zbyszko')
          expect(JSON.parse(subject.body)['last']).to eq('Bogdanca')
        end
      end

      describe 'multiple users found in LDAP' do
        before do
          allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
            { 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'] },
            { 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'] }
          ])
        end

        subject { get :verify_user, q: 'Zbyszko Z Bogdanca' }

        it { is_expected.to have_http_status(:success) }

        it 'indicates that user is not verified' do
          expect(JSON.parse(subject.body)['verified']).to be_falsy
          expect(JSON.parse(subject.body)['message']).to match(/multiple users/)
        end
      end

      describe 'user not found in LDAP' do
        before do
          allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([])
        end

        subject { get :verify_user, q: 'Sbyszko Z Bogdanca' }

        it { is_expected.to have_http_status(:success) }

        it 'indicates that user is not verified' do
          expect(JSON.parse(subject.body)['verified']).to be_falsy
          expect(JSON.parse(subject.body)['message']).to match(/not found in the/)
        end
      end
    end
  end # verify_user

  describe '#query_users' do
    context 'invalid query' do
      describe 'no params passed' do
        subject { get :query_users }

        it { is_expected.to have_http_status(:success) }

        it 'returns empty array' do
          expect(JSON.parse(subject.body)).to be_blank
        end
      end

      describe 'short param passed' do
        subject { get :query_users, q: 'Zb' }

        it { is_expected.to have_http_status(:success) }

        it 'returns empty array' do
          expect(JSON.parse(subject.body)).to be_blank
        end
      end
    end

    context 'valid query' do
      describe 'multiple users found in LDAP' do
        before do
          allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
            { 'uid' => ['id1'], 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'] },
            { 'uid' => ['id2'], 'givenName' => ['Trysko'], 'sn' => ['Tutanca'] }
          ])
        end

        subject { get :query_users, q: 'anca' }

        it { is_expected.to have_http_status(:success) }

        it 'returns a properly formatted names' do
          expect(JSON.parse(subject.body)).to include({
            'id' => 'id1', 'label' => 'Bogdanca, Zbyszko'
          })
          expect(JSON.parse(subject.body)).to include({
            'id' => 'id2', 'label' => 'Tutanca, Trysko'
          })
        end
      end

      describe 'user not found in LDAP' do
        before do
          allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([])
        end

        subject { get :query_users, q: 'Sbyszko Z Bogdanca' }

        it { is_expected.to have_http_status(:success) }

        it 'returns empty array' do
          expect(JSON.parse(subject.body)).to be_blank
        end
      end
    end
  end # query_users
end
