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
          allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([{
            'givenName' => ['Zbyszko'],
            'sn' => ['Bogdanca'],
            'uid' => ['zbych101']
          }])
        end

        subject { get :verify_user, q: 'Zbyszko Z Bogdanca' }

        it { is_expected.to have_http_status(:success) }

        it 'indicates that user is verified' do
          expect(JSON.parse(subject.body)['verified']).to be_truthy
        end

        it 'returns users first and last name' do
          expect(JSON.parse(subject.body)['standardized_name']).to eq(
            'Bogdanca, Zbyszko')
        end

        it 'returns an empty vivo hash for non-matching netid' do
          expect(JSON.parse(subject.body)['vivo']).to be_blank
        end

        describe 'netid maps to vivoid' do
          before do
            create(:net_id_to_vivo_id, netid: 'zbych101', vivoid: 'vivo101',
                   full_name: 'Z Bogdanca, Zbyszko Czarny')
          end

          it 'returns vivo profile link' do
            expect(JSON.parse(subject.body)['vivo']['profile']).to eq(
              'http://vfsmvivo.fsm.northwestern.edu/vivo/individual?uri=http%3A%2F%2Fvivo.northwestern.edu%2Findividual%2Fvivo101')
          end

          it 'returns full name from vivo' do
            expect(JSON.parse(subject.body)['vivo']['full_name']).to eq(
              'Z Bogdanca, Zbyszko Czarny')
          end
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

    context 'generates valid LDAP query' do
      describe 'with partial ORCID' do
        subject { get :query_users, q: '0000-0003-4105' }

        specify do
          expect_any_instance_of(Nuldap).to receive(:multi_search).with(
            "(|(&(cn=0000-0003-4105*))(uid=0000-0003-4105*))"
          ).and_return([])
          expect(subject).to have_http_status(:success)
        end
      end

      describe 'with full ORCID' do
        subject { get :query_users, q: '0000-0003-4105-1234' }

        specify do
          expect_any_instance_of(Nuldap).to receive(:multi_search).with(
            "(|(&(cn=0000-0003-4105-1234*))(uid=0000-0003-4105-1234*)(eduPersonOrcid=https://orcid.org/0000-0003-4105-1234))"
          ).and_return([])
          expect(subject).to have_http_status(:success)
        end
      end
    end

    context 'valid query' do
      describe 'multiple users found in LDAP' do
        before do
          allow_any_instance_of(Nuldap).to receive(:multi_search).and_return([
            { 'uid' => ['id1'], 'givenName' => ['Zbyszko'], 'sn' => ['Bogdanca'],
              'nuMiddleName' => ['z']
            },
            { 'uid' => ['id2'], 'givenName' => ['Trysko'], 'sn' => ['Tutanca'] }
          ])
        end

        subject { get :query_users, q: 'anca' }

        it { is_expected.to have_http_status(:success) }

        it 'returns a properly formatted names' do
          expect(JSON.parse(subject.body)).to include({
            'id' => 'id1', 'label' => 'Bogdanca, Zbyszko z'
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

  describe '#lcnaf_names', :vcr do
    context 'invalid query' do
      describe 'no params passed' do
        subject { get :lcnaf_names }

        it { is_expected.to have_http_status(:success) }

        it 'returns empty array' do
          expect(subject["response"]).to be_nil
        end
      end

      describe 'no results returned' do
        subject { JSON.parse(get(:lcnaf_names, q: 'fictional name').body) }

        it 'returns empty array' do
          expect(subject.count).to eq(0)
        end
      end
    end

    context 'valid query' do
      context 'lower case query' do
        subject { JSON.parse(get(:lcnaf_names, q: 'name').body) }

        it 'returns values from LOC' do
          expect(subject.count).to eq(10)
          subject.each{ |s|
            expect(s.downcase).to include('name')
          }
        end
      end

      context 'upper case query' do
        subject { JSON.parse(get(:lcnaf_names, q: 'NAME').body) }

        it 'returns values from LOC' do
          expect(subject.count).to eq(10)
          subject.each{ |s|
            expect(s.downcase).to include('name')
          }
        end
      end

      context 'with one result' do
        subject { JSON.parse(get(:lcnaf_names, q: 'galter, dollie').body) }

        it 'returns one value from LOC' do
          expect(subject.count).to eq(1)

          expect(subject.first.downcase).to include('galter, dollie')
        end
      end
    end
  end # lcnaf_names

  describe '#query_mesh', :vcr do
    context 'invalid query' do
      describe 'no params passed' do
        subject { get :query_mesh }

        it { is_expected.to have_http_status(:success) }

        it 'returns empty array' do
          expect(subject["response"]).to be_nil
        end

        describe 'no results returned' do
          subject { JSON.parse(get(:query_mesh, q: 'nothing').body) }

          it 'returns empty array' do
            expect(subject.count).to eq(0)
          end
        end
      end
    end

    context 'valid query' do
      context 'lower case query' do
        subject { JSON.parse(get(:query_mesh, q: 'test').body) }

        it 'returns values from MeSH sparql' do
          expect(subject.count).to eq(10)
          subject.each{ |s|
            expect(s.downcase).to include('test')
          }
        end
      end

      context 'upper case query' do
        subject { JSON.parse(get(:query_mesh, q: 'TEST').body) }

        it 'returns values from MeSH sparql' do
          expect(subject.count).to eq(10)
          subject.each{ |s|
            expect(s.downcase).to include('test')
          }
        end
      end

      context 'with one result' do
        subject { JSON.parse(get(:query_mesh, q: 'translational sciences').body) }

        it 'returns one value from MeSH sparql' do
          expect(subject.count).to eq(1)

          expect(subject.first.downcase).to include('translational sciences')
        end
      end
    end
  end
end
